// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CryptoLendingToken.sol";

contract CryptoLendingBuySell {
    // @title CryptoLendingBuySell contract that the user can buy or sell CL token
    // @noticeThe tokan can be use from borrowers to sell their CL tokens in whatever amount wants. Users can buy the token 
    // if is available by sending the totalAmount that is provided in BuySellCryptoLending details.
    // the contract to work need the CryptoLendingToken contract and the token smart contract address must be set when the contract is created
    // Also the vault address must be set too and will be use to receive all the comission fees from the tokens that be sold.

    // global variables
    CryptoLendingToken cryptoLendingToken;
    address vault;
    uint commissionRate = 1;
      
    // enum of buysell status
    enum ESTATUS {
        ACTIVE,
        SOLD,
        CANCELLED
    }

    // buySell details
    struct BuySellCryptoLending {
        uint256 tokenId;
        ESTATUS status;
        uint256 amount;
        uint256 commissionAmount;
        uint256 totalAmount;
        uint createdAt;
        uint soldAt;
        bool exist;
    }

    // Events
    event notifySell(uint256 _tokenId, uint256 totalAmount);
    event notifyBuy(uint256 _tokenId, address newOwner);
    event notifyCancel(uint256 _tokenId);

    // maps for storing BuySellCryptoLending details and as a key value is the id of token
    mapping(uint256 => BuySellCryptoLending) public buySellCryptoLendings;


    // @notice Middleware to check if the token exists with the specific id
    // @param _tokenId The token id of the erc721 token
    modifier tokenExists(uint256 _tokenId) {
        require(cryptoLendingToken.ownerOf(_tokenId) != address(0), "Token not exist");
        _;
    }

    // @notice Middleware to check if the sender is owner of the speicific token id
    // @param _tokenId The token id of the erc721 token
    modifier isTokenOwner(uint256 _tokenId) {
        require(cryptoLendingToken.ownerOf(_tokenId) == msg.sender, "The sender is not owner of the specific token");
        _;
    }

    // @notice setting CL token address and vault address
    // @param _cryptoLendingTokenAddress is the address of the CL token
    // @param _vaultAddress is the address that will send the commission amounts;
    constructor(address _cryptoLendingTokenAddress, address _vaultAddress) {
        cryptoLendingToken = CryptoLendingToken(_cryptoLendingTokenAddress);
        vault = _vaultAddress;
    }

    // @notice getting the request details;
    // @param _tokenId The token id of the erc721 token
    // @return request details
    function get(uint256 _tokenId) public view returns(BuySellCryptoLending memory) {
        return buySellCryptoLendings[_tokenId];
    }

    // @notice The borrower user can sell the CL token that owns to other user. 
    // But first the borrower user must be sure that approve this contract to make safeTransfer when the token is sold
    // also the contract getting commission when the token will be sold.
    // @param _tokenId The token id of the erc721 token
    // @param _amount The amount that the token owners wants to sell the token. 
    // @event notify through event that there is token for sale.
    function sell(uint256 _tokenId, uint256 _amount) tokenExists(_tokenId) isTokenOwner(_tokenId) public {
        require(!buySellCryptoLendings[_tokenId].exist || (buySellCryptoLendings[_tokenId].exist  && buySellCryptoLendings[_tokenId].status != ESTATUS.ACTIVE), "The token is already for sale");
        require(cryptoLendingToken.getApproved(_tokenId) != address(0), "This contract doesn't have access to transfer the token");
        require(_amount > 0, "Sorry your not allowed to sell the token for free");
        _amount = _amount * 1 ether;
        uint256 commissionAmount = _amount * commissionRate / 100;
        uint256 totalAmount = _amount + commissionAmount;
        buySellCryptoLendings[_tokenId].status = ESTATUS.ACTIVE;
        buySellCryptoLendings[_tokenId].amount = _amount;
        buySellCryptoLendings[_tokenId].commissionAmount = commissionAmount;
        buySellCryptoLendings[_tokenId].totalAmount = totalAmount;
        buySellCryptoLendings[_tokenId].createdAt = block.timestamp;
        buySellCryptoLendings[_tokenId].soldAt = 0;
        buySellCryptoLendings[_tokenId].exist = true;
        emit notifySell(_tokenId, totalAmount);
    }

    // @notice User can buy the token that is listed by sending the totalAmount(amount + commissionAmount)
    // the function will send the BNB amount to the borrower and the comission amount to the vault address of the contract.
    // The final step the function is sending using safeTransferFrom function from ERC-721 open zeppelin contract the token to the new owner
    // @param _tokenId The token id of the erc721 token
    // @event notify through event that the token is sold to a specific address
    function buy(uint256 _tokenId) payable public tokenExists(_tokenId) {
        require(buySellCryptoLendings[_tokenId].status == ESTATUS.ACTIVE, "The token is not available for Sale");
        require(cryptoLendingToken.ownerOf(_tokenId) != msg.sender, "Already you own this token");
        require(buySellCryptoLendings[_tokenId].totalAmount == msg.value, "Amount is not match with payable amount");
        buySellCryptoLendings[_tokenId].status = ESTATUS.SOLD;
        buySellCryptoLendings[_tokenId].soldAt = block.timestamp;
        payable(cryptoLendingToken.ownerOf(_tokenId)).transfer(buySellCryptoLendings[_tokenId].amount);
        payable(vault).transfer(buySellCryptoLendings[_tokenId].commissionAmount);
        cryptoLendingToken.safeTransferFrom(cryptoLendingToken.ownerOf(_tokenId), msg.sender, _tokenId);
        emit notifyBuy(_tokenId, msg.sender);
    }

    // @notice Borrower cancelling the token to be sold to other users
    // @param tokenId The token id of the erc721 token
    // @event notify through event that the token is not available for sale.
    function cancelSell(uint256 _tokenId) external tokenExists(_tokenId) isTokenOwner(_tokenId)  {
        require(buySellCryptoLendings[_tokenId].status == ESTATUS.ACTIVE, "Token is already Cancelled");
        buySellCryptoLendings[_tokenId].status = ESTATUS.CANCELLED;
        emit notifyCancel(_tokenId);
    }
}
