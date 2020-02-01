# Avoiding Common Attacks

## Re-entracy Attacks (SWC-107)

To prevent **re-entrancy attacks**, all the `payable` functions perform update in the storage *before* sending the payment to the image owner or licensee. For example, in the function `approveLicenseRequest`, the status of the license request is changed to `Approved` before the payment is done. Without that it would be possible to the image owner to receive the value for the license multiple times. The same logic applies to the functions `refuseLicenseRequest` and `cancelLicenseRequest`.


## Transaction Ordering and Timestamp Dependence (SWC-114)

**Not applicable**: No logic in the contract is dependent of time.


## Integer Overflow and Underflow (SWC-101)

**Not applicable**: No aritmetic operations are done in any part of the contracts. IDS are big enough (uint256) to not overflow. 


## Denial of Service with Failed Call (SWC-113)

**Not applicable**: Fails in the payments to image owners (or refund to licensees) will not affect the functionality of the smart contract for other users. 


## Denial of Service by Block Gas Limit or startGas (SWC-128)

**TODO**: The function `getLicensableImages` is susceptible to DoS by block gas limit if the amount of capsules to iterate grows. The solution to this problem is to create a pagination (or cursor) mechanism adding two extra params to the function signature: `uint pageNum` and uint `pageSize`. With this in place it's possible to start the iteration from a specific index and limit the amount of returned results. 


## Force Sending Ether

**No applicable**: The implemented code does not depend on the contract balance. 