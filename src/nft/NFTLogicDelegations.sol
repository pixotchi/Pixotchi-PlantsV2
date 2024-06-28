// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library NFTLogicDelegations {
    /**
     * @dev Performs a delegatecall to the `_tokenBurnAndRedistribute` function of the target contract.
     * @param target The address of the target contract.
     * @param account The address of the account.
     * @param amount The amount to be burned and redistributed.
     */
    function _tokenBurnAndRedistribute(address target, address account, uint256 amount) internal {
        (bool success, ) = target.delegatecall(
            abi.encodeWithSignature("_tokenBurnAndRedistribute(address,uint256)", account, amount)
        );
        require(success, "Delegatecall to _tokenBurnAndRedistribute failed");
    }

    // /**
    //  * @dev Example function that performs a delegatecall and captures the return data.
    //  * @param target The address of the target contract.
    //  * @param account The address of the account.
    //  * @param amount The amount to be processed.
    //  * @return result The result of the delegatecall.
    //  */
    // function _delegateWithReturnValue(address target, address account, uint256 amount) internal returns (bytes memory result) {
    //     (bool success, bytes memory data) = target.delegatecall(
    //         abi.encodeWithSignature("_processAndReturn(address,uint256)", account, amount)
    //     );
    //     require(success, "Delegatecall to _processAndReturn failed");
    //     return data;
    // }
}