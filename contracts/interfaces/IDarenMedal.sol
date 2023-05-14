// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDarenMedal {
    struct Order {
        uint256 pk;
        uint256 tokenId;
        uint256 price; // in wei
        address seller;
        uint256 createdAt;
    }

    event OrderCreated(
        uint256 tokenId,
        uint256 price,
        address seller,
        uint256 createdAt
    );

    event OrderCanceled(uint256 tokenId);

    event OrderExecuted(
        uint256 tokenId,
        uint256 price,
        address buyer,
        address seller,
        uint256 createdAt
    );
}
