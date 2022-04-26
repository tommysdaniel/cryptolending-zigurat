// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoLendingRequestChecks {
    // @title CryptoLending Request check contract to truck all the actions of the borrower and lender
    // @notice For every action that borrower and lender is execute is setting to true specific variable


    // @notice Global variables that will be used to track the actions of borrower and lender
    bool public borrowerClaimed;
    bool public borrowerDepositCollateral;
    bool public borrowerWithdrawCollateral;
    bool public borrowerPaidAmount;
    bool public lenderDeposit;
    bool public lenderClaimed;

    // @notice when the contract is created is setting to false all the global variables of the contract
    constructor() public {
        borrowerClaimed = false;
        borrowerDepositCollateral = false;
        borrowerWithdrawCollateral = false;
        borrowerPaidAmount = false;
        lenderDeposit = false;
        lenderClaimed = false;
    }

    // @notice setting the borrower deposit collateral variable to true and checking that is not already deposited
    function setDepositCollateral() external {
        require(borrowerDepositCollateral == false, "Collateral is already deposited");
        borrowerDepositCollateral = true;
    }

    // @notice setting the borrower withdraw collateral variable to true and checking that is not already withdraw
    function setWithdrawCollateral() external {
        require(borrowerWithdrawCollateral == false, "Collateral is already withdraw");
        borrowerWithdrawCollateral = true;
    }

    // @notice setting the lending deposit variable to true and checking that is not already deposit the amount
    function setDepositLending() external {
        require(lenderDeposit == false, "Lender amount is already deposited");
        lenderDeposit = true;
    }

    // @notice setting the Borrower paid amount variable to true and checking that is not already paid the amount
    function setBorrowerPaidAmount() external {
        require(borrowerPaidAmount == false, "Borrower  is already paid the amount");
        borrowerPaidAmount = true;
    }

    // @notice setting the Lending claim variable to true and checking that is not already claimed
    function setLendingClaimed() external {
        require(lenderClaimed == false, "Lender is already claimed the deposit amount and interest amount");
        lenderClaimed = true;
    }
}
