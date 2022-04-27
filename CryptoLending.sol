// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CryptoLendingToken.sol";
import "./CryptoLendingRequest.sol";
import "./CryptoLendingRequestChecks.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// @notice interface of crypto lending request contract
interface ICryptoLendingRequest {
    function get() external view returns(CryptoLendingRequest.Request memory);
    function nextStatus() external;
    function activate() external;
    function setLenderAddress(address lender) external;
    function updateCollateralAmount() external;
    function cancelRequest() external;
}

// @notice interface of crypto lending request checks contract
interface ICryptoLendingRequestChecks {
    function setDepositCollateral() external;
    function setDepositLending() external;
    function setBorrowerPaidAmount() external;
    function setLendingClaimed() external;
    function setWithdrawCollateral() external;
    function borrowerClaimed() external view returns (bool);
    function borrowerDepositCollateral() external view returns (bool);
    function borrowerWithdrawCollateral() external view returns (bool);
    function borrowerPaidAmount() external view returns (bool);
    function lenderDeposit() external view returns (bool);
    function lenderClaimed() external view returns (bool);
}


contract CryptoLending is CryptoLendingToken {

    // Safe math contract for numbers
    using SafeMath for uint256;

    // counter to increase the id number
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    // global variables
    address vault;
    uint commissionRate = 1;
    uint collateralRate = 200;
    uint duration = 365;

    // Event
    event notifyCryptoLendingRequestStatus(uint256 _id, CryptoLendingRequest.ESTATUS status);

    // maps for storing CryptoLending Request contract addresses
    mapping(uint256 => CryptoLendingRequest) public cryptoLendingRequests;
    mapping(uint256 => CryptoLendingRequestChecks) public cryptoLendingRequestChecks;


    // @notice Middleware to check if the crypto lending request exist before execute the function
    // @param _id The id of the created crypto lending request
    modifier cryptoLendingRequestExists(uint256 _id) {
        require(address(cryptoLendingRequests[_id]) != address(0), "Crypto lending request not exist");
        _;
    }

    // @notice Middleware to check if the crypto lending request is initialized or pending
    // @param _id The id of the created crypto lending request
    modifier cryptoLendingPrepareStatus(uint256 _id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        CryptoLendingRequest.ESTATUS status = cryptoLendingRequest.get().status;
        require(status == CryptoLendingRequest.ESTATUS.INITIALIZED || status == CryptoLendingRequest.ESTATUS.PENDING, "This crypto lending request is not initialized or pending");
        _;
    }

    // @notice Middleware to check if the crypto lending request is not cancelled
    // @param _id The id of the created crypto lending request
    modifier isCryptoLendingRequestNotCancelled(uint256 _id) {
        require(ICryptoLendingRequest(address(cryptoLendingRequests[_id])).get().status != CryptoLendingRequest.ESTATUS.CANCELLED, "This crypto lending request is cancelled");
        _;
    }

    // @notice Middleware to check if the sender is the borrower of the crypto lending request
    // @param _id The id of the created crypto lending request
    modifier isBorrower(uint256 _id) {
        require(ICryptoLendingRequest(address(cryptoLendingRequests[_id])).get().borrowerAddress == msg.sender, "The address is not borrower for the specific crypto lending request");
        _;
    }

    // @notice Middleware to check if the sender is the lender of the crypto lending requests
    // @param _id The id of the created crypto lending request
    modifier isLender(uint256 _id) {
        require(ICryptoLendingRequest(address(cryptoLendingRequests[_id])).get().lenderAddress == msg.sender, "The address is not lender for the specific crypto lending request");
        _;
    }

    // @notice setting vault address when the contract when the contract is initialized
    // @param _vaultAddress is the address that will send the commission amounts;
    constructor(address _vaultAddress) {
        vault = _vaultAddress;
    }

    // @notice Getting crypto lending details by calling the get() function from CryptoLendingRequest contract
    // @param _id The token id of the created crypto lending request
    // @return return the crypto lending request details
    function getCryptoLending(uint256 _id) external view cryptoLendingRequestExists(_id) returns(CryptoLendingRequest.Request memory) {
        return ICryptoLendingRequest(address(cryptoLendingRequests[_id])).get();
    }

    // @notice Creating new crypto lending request using the CryptoLendingRequest contract 
    // @param _amount The amount of the cryprto lending request
    // @param _interestRate The interest rate of the crypto lending request
    // @return return the crypto lending request id 
    function requestCryptoLending(uint _amount, uint _interestRate) external returns(uint256 tokenId) {
        require(_amount * 1 ether >= 1 ether, "Amount must higher than 1 ether");
        require(_interestRate > 0, "Interest rate must be higher than 0");
        counter.increment();
        CryptoLendingRequest cryptoLendingRequest = new CryptoLendingRequest(
            counter.current(),
            msg.sender,
            _amount * 1 ether,
            _interestRate,
            commissionRate,
            collateralRate,
            duration
        );
        cryptoLendingRequests[counter.current()] = cryptoLendingRequest;
        cryptoLendingRequestChecks[counter.current()] = new CryptoLendingRequestChecks();

        return counter.current();
    }

    function borrowerCancelRequest(uint256 _id) external cryptoLendingRequestExists(_id) cryptoLendingPrepareStatus(_id) isBorrower(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        // check if collateral deposit
        // check if lender  deposit
        cryptoLendingRequest.cancelRequest();
    }

    // @notice Borrower sending deposit of the collateral of the crypto lending request
    // @param _id The id of the created crypto lending request
    // @event notify through event the change of crypto lending request status - Pending or Ready
    function borrowerCollateral(uint256 _id) external payable cryptoLendingRequestExists(_id) cryptoLendingPrepareStatus(_id) isBorrower(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).borrowerDepositCollateral() == false, "The crypto lending request already have collateral");
        require(msg.value == cryptoLendingRequest.get().collateralAmount, "Collateral amount is not match with payable amount");
        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setDepositCollateral();
        cryptoLendingRequest.nextStatus();
        emit notifyCryptoLendingRequestStatus(_id, cryptoLendingRequest.get().status);
    }



    // @notice Lender depositing the amount of the lending request
    // @param _id The id of the created crypto lending request
    // @event notify through event the change of crypto lending request status - Pending or Ready
    function lenderDeposit(uint256 _id) external payable cryptoLendingRequestExists(_id) cryptoLendingPrepareStatus(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(cryptoLendingRequest.get().lenderAddress == address(0), "The crypto lending request already have Lender");
        require(cryptoLendingRequest.get().borrowerAddress != msg.sender, "The lender address must be different from borrower");
        require(msg.value == cryptoLendingRequest.get().amount, "Amount is not match with payable amount");

        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setDepositLending();
        cryptoLendingRequest.setLenderAddress(msg.sender);
        cryptoLendingRequest.nextStatus();
        emit notifyCryptoLendingRequestStatus(_id, cryptoLendingRequest.get().status);
    }

    // @notice Borrower activate crypto lending request if collateral deposited and the lender deposit the needed amount
    // @param _id The id of the crypto lending request
    // @event notify through event the change of crypto lending request status - from Ready to Active
    function borrowerActiveCryptoLending(uint256 _id) external cryptoLendingRequestExists(_id) isBorrower(_id) isCryptoLendingRequestNotCancelled(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(cryptoLendingRequest.get().status != CryptoLendingRequest.ESTATUS.ACTIVE, "The crypto lending request is already active");
        require(cryptoLendingRequest.get().status == CryptoLendingRequest.ESTATUS.READY, "To active the crypto lending request must be in READY status");

        cryptoLendingRequest.nextStatus();
        cryptoLendingRequest.activate();
        transferAmount(msg.sender,  cryptoLendingRequest.get().amount);
        mintToken(cryptoLendingRequest.get().lenderAddress, _id);
        emit notifyCryptoLendingRequestStatus(_id, cryptoLendingRequest.get().status);
    }


    // @notice Borrower sending the total amount of the crypto lending request to repay it before the maturity date
    // @param _id The id of the crypto lending request
    // @event notify through event the repayment of crypto lending request and the current status - from active to completed
    function borrowerRepayAmount(uint256 _id) external payable cryptoLendingRequestExists(_id) isBorrower(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(cryptoLendingRequest.get().status == CryptoLendingRequest.ESTATUS.ACTIVE, "The crypto lending request is not active");
        require(cryptoLendingRequest.get().maturityDate > block.timestamp, "Maturity Date passed");
        require(msg.value == cryptoLendingRequest.get().totalAmount, "Total Amount is not match with payable amount");

        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setBorrowerPaidAmount();
        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setWithdrawCollateral();
        cryptoLendingRequest.nextStatus();
        transferAmount(msg.sender, cryptoLendingRequest.get().collateralAmount);
        emit notifyCryptoLendingRequestStatus(_id, cryptoLendingRequest.get().status);
    }


    // @notice Lender claiming the amount that was deposit plus the interest of the crypto lending request.
    // If the borrower not repaid the crypto lending request before the maturity date
    // then the lender can claiming amount will be taking from the collateral deposit of the borrower
    // @param _id The id of the crypto lending request
    // @event notify through event the lender claiming amount and the status of crypto lending request - from active to completed
    function lenderClaimAmount(uint256 _id) external cryptoLendingRequestExists(_id) {
        require(ownerOf(_id) == msg.sender, "The sender is not owner of the specific token");
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).lenderClaimed() == false, "You have already claimed the amount");
        require(cryptoLendingRequest.get().status == CryptoLendingRequest.ESTATUS.COMPLETED ||  cryptoLendingRequest.get().maturityDate > block.timestamp, "The crypto lending request is not completed yet");
        if (ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).borrowerPaidAmount() == false) {
            cryptoLendingRequest.updateCollateralAmount();
        }
        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setLendingClaimed();
        cryptoLendingRequest.nextStatus();
        transferAmount(msg.sender, cryptoLendingRequest.get().totalAmount - cryptoLendingRequest.get().commissionAmount);
        transferAmount(vault, cryptoLendingRequest.get().commissionAmount);

        burnToken(_id);
        emit notifyCryptoLendingRequestStatus(_id, cryptoLendingRequest.get().status);
    }


    // @notice Borrower withdraw collateral after lender claiming the total amount from the collateral
    // @param _id The id of the crypto lending request
    function withdrawCollateral(uint256 _id) external cryptoLendingRequestExists(_id) isBorrower(_id) {
        ICryptoLendingRequest cryptoLendingRequest = ICryptoLendingRequest(address(cryptoLendingRequests[_id]));
        require(ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).borrowerWithdrawCollateral() == false, "You have already withdrawal the collateral");
        require(cryptoLendingRequest.get().status == CryptoLendingRequest.ESTATUS.COMPLETED, "The crypto lending request is not completed yet");
        transferAmount(msg.sender, cryptoLendingRequest.get().collateralAmount);
        ICryptoLendingRequestChecks(address(cryptoLendingRequestChecks[_id])).setWithdrawCollateral();
    }

    // @notice use to transfer amount to specific address
    // @param toAddress The address that the amount will be transfer
    // @param amount The amount that will be send to the toAddress
    function transferAmount(address toAddress, uint256 amount) private {
        payable(toAddress).transfer(amount);
    }

    // @notice use to generate new ERC-721 token that will take the id of the crypto lending request
    // and will transfer to the lender of the contract
    // @param lenderAddress the address of the lender
    // @param _tokenId The token No. will have the same id as the crypto lending request
    function mintToken(address lenderAddress, uint256 _tokenId) private {
        _mint(lenderAddress, _tokenId);
    }

    // @notice use to burn the token of the specific crypto lending requests
    // @param _tokenId the id of the token that will burn when the lender claim the deposit
    // and interest from the crypto lending request when is expired or completed.
    function burnToken(uint256 _tokenId) private {
        _burn(_tokenId);
    }
}
