// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoLendingRequest {

    // Safe math contract for numbers;
    using SafeMath for uint256;

    // enum of request status
    enum ESTATUS {
        INITIALIZED,
        PENDING,
        READY,
        ACTIVE,
        COMPLETED,
        CANCELLED
    }

    // request details
    struct Request {
        uint256 id;
        ESTATUS status;
        uint256 amount;
        uint256 interestAmount;
        uint256 commissionAmount;
        uint256 collateralAmount;
        uint256 totalAmount;
        uint duration;
        uint createdAt;
        uint startDate;
        uint maturityDate;
        address borrowerAddress;
        address lenderAddress;
    }

    // global variable
    Request private request;

    // @notice setting request details when is created
    // @param _id is the number of the request
    // @param _borrowerAddress the address of the borrower
    // @param _amount is the amount that borrower need
    // @param _interestRate is the percentage of the interest that will be used to calculate the interestAmount
    // @param _commissionRate is the percentage of the commission that will be used to calculate the commissionAmount
    // @param _collateralRate is the percentage of the collateral that will be used to calculate collateralAmount
    // @param _duration is the number of days of the lending
    constructor(
        uint256 _id,
        address _borrowerAddress,
        uint _amount,
        uint _interestRate,
        uint _commissionRate,
        uint _collateralRate,
        uint _duration
    ) public {
        uint256 interestAmount = _amount * _interestRate / 100;
        uint256 commissionAmount = _amount * _commissionRate / 100;
        uint256 collateralAmount = _amount * _collateralRate / 100;
        uint256 totalAmount = _amount + interestAmount + commissionAmount;
        request.id = _id;
        request.status = ESTATUS.INITIALIZED;
        request.amount = _amount;
        request.interestAmount = interestAmount;
        request.collateralAmount = collateralAmount;
        request.commissionAmount = commissionAmount;
        request.totalAmount = totalAmount;
        request.duration = _duration;
        request.createdAt = block.timestamp;
        request.startDate =  0;
        request.maturityDate = 0;
        request.borrowerAddress = _borrowerAddress;
        request.lenderAddress = address(0);
    }

    // @notice getting the request details;
    // @return request details
    function get() public view returns(Request memory) {
        return request;
    }


    // @notice updating the status of the crypto lending request
    function nextStatus()  external {
        if(request.status == ESTATUS.INITIALIZED) {
            request.status = ESTATUS.PENDING;
        } else if(request.status == ESTATUS.PENDING) {
            request.status = ESTATUS.READY;
        } else if(request.status == ESTATUS.READY) {
            request.status = ESTATUS.ACTIVE;
        } else if(request.status == ESTATUS.ACTIVE) {
            request.status = ESTATUS.COMPLETED;
        }
    }

    // @notice setting the status of crypto lending request to cancel
    function cancelRequest() external {
        request.status = ESTATUS.CANCELLED;
    }

    // @notice Activate Updating the startDate with current date
    // and calculate the maturityDate from current date plus duration days
    function activate() external {
        request.startDate = block.timestamp;
        request.maturityDate = block.timestamp + request.duration * 1 days;
    }

    // @notice setting the lender address of the crypto lending request
    // @param _lenderAddress The address of the lender
    function setLenderAddress(address _lenderAddress) external {
        request.lenderAddress = _lenderAddress;
    }

    // @notice subtracting the collateralAmount in case of the borrower not repay the loan before the maturity date
    function updateCollateralAmount() external {
        request.collateralAmount = request.collateralAmount.sub(request.totalAmount);
    }
}
