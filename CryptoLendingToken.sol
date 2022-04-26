// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CryptoLendingToken is ERC721 {
    // @title CryptoLending Token contract is use to generate ERC-721 tokens for cryptoLendingRequest tokens
    // @notice Every new crypto lending request that is active. a new ERC-721 token is minted with itemNo the id of the lending request
    // and when the borrower is claim the deposit and interest the token will burn.
    // For CryptoLendingBuySell contract the borrower user must approve the buySell contract to have access for sending the token when a user buy it.
    constructor() ERC721("CryptoLending", "CL") {

    }
}
