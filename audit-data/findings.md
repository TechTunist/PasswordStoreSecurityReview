### [H-1] Storing the password on chain makes it visible to anyone

**Description:** All data stored on-chain is visible to anyone and can be read directly on the blockchain.
The `PasswordStore::s_password` variable is intended to be private and only accessed through the `PasswordStore::getPassword` function, which is 
intended to opnly be callable by the owner of the contract.

**Impact:** Anyone can read the private password, severly breaking the functioanlity of the protocol.

**Proof of Concept:**
The below test case shows how anyone can read the password directly from the blockchain.

1. Create a locally running chain
   ```
   make anvil
   ```

2. Deploy the contract to the chain
   ```
   make deploy
   ```

3. Run the storage tool to obtain the bytes object
   ```
   cast storage <contract address> 1
   ```

4. Decode the bytes-32 encoding of the password 'myPassword'
   ```
   cast parse-bytes32-string <bytes object>
   ```

5. The output is "myPassword"

**Recommended Mitigation:**
The fundamental functionality is flawed, as to implement the objective of storing passwords securely 
would require the password to be encrypted off-chain before being stored on-chain. This eliminates
the utility of retrieving the password by owning a contract as a separate password would be necessary for decryption.



### Likelihood & Impact
- Impact:      HIGH
- Likelihood:  HIGH
- Severity:    HIGH

### [H-2] The function `PasswordStore::setPassword` has no access controls, meaning that anyone has the power to set the password by calling this function.

**Description:** The `PasswordStore::setPassword` function is designed to be callable from outside of the contract, so is set to `external`.
Since the intention is to only allow the contract owner to be able to call the contract, there needs to be access control set up.
In `PasswordStore::getPassword`, the function uses `if (msg.sender != s_owner)` to check if the caller is the contract owner, and reverts if this check fails.
This functionality should also be implemented in `PasswordStore::setPassword` to prevent the function being called by non-owners of the contract.

```javascript
function setPassword(string memory newPassword) external {
@>      // @audit = there are no access controls
        s_password = newPassword;
        emit SetNetPassword();
    }
```

**Impact:** Anyone can set or change the value of the `s_password` variable, severely breaking contract functionality.

**Proof of Concept:** The below test was added to the testing suite and is written specifically for this audit to demonstrate how a non_owner can set the password.
In the `test/PasswordStore.t.sol` file, a random address is generated on line 14: `address public NOT_OWNER = makeAddr("non_owner");`. This `NOT_OWNER` address
is then passed to `startPrank()` before the `setPassword` function is called, making sure the password is set by the `NON_OWNER` user, before `stopPrank()` is called.
`vm.startPrank()` is called again this time with `owner` as the argument, which is the contract's owner as defined on line 11: `owner = msg.sender'`. This had to be
done as the `getPassword` function requires the owner be the one calling it. The test asserts that the expected password matches the actual password that is set by
the `NOT_OWNER` address. The `console.log` at the end of the test prints out the addresses of the `owner` and the `NOT_OWNER` to prove they are not the same. 

<details>
<summary> Code </summary>

```javascript
    // @audit test to prove that non_owners can set the password
    function test_non_owner_can_set_password() public {
        vm.startPrank(NOT_OWNER);
        string memory expectedPassword = "thisWasSetByANonOwnerFromAddress";
        passwordStore.setPassword(expectedPassword);
        vm.stopPrank();

        vm.startPrank(owner);
        string memory actualPassword = passwordStore.getPassword();
        passwordStore.setPassword("thisWasSetByANonOwnerFromAddress:");
        assertEq(actualPassword, expectedPassword);
    
        console.log("The password: ", passwordStore.getPassword(), " was changed by the non-owner", NOT_OWNER);
        console.log("The owner's address: ", owner, "The address of the user that set the password: ", NOT_OWNER);
        vm.stopPrank();
    }
```
</details>

<br>

To run the test:
```bash
forge test --mt test_non_owner_can_set_password -vv
```
will produce this output: 
```bash
[⠔] Compiling...
No files changed, compilation skipped

Running 1 test for test/PasswordStore.t.sol:PasswordStoreTest
[PASS] test_non_owner_can_set_password() (gas: 80699)
Logs:
  The password:  thisWasSetByANonOwnerFromAddress:  was changed by the non-owner 0x60486071f6c0CB74fF59C85755fa6C3E38A70064
  The owner's address:  0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 The address of the user that set the password:  0x60486071f6c0CB74fF59C85755fa6C3E38A70064

Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.37ms
 
Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

**Recommended Mitigation:** Add an access control conditional to the `setPassword` function. The existing example in `getPassword` would be sufficient:
```javascript
if (msg.sender != s_owner) {
            revert PasswordStore__NotOwner();
        }
```


### Likelihood & Impact
- Impact:      HIGH
- Likelihood:  HIGH
- Severity:    HIGH 

### [I-1] Natspec incorrectly specifies a parameter for the setPassword function.

**Description:**
```javascript
/*
     * @notice This allows only the owner to retrieve the password.
     * @param newPassword The new password to set.
*/
```

**Impact:** The natspec is incorrect


**Recommended Mitigation:** Amend the natspec to correctly describe the usage of the `getPassword` function.

```diff
- * @param newPassword The new password to set.

```


### Likelihood & Impact
- Impact:      NONE
- Likelihood:  NONE
- Severity:    INFORMATION/GAS/NON-CRITS