// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMetadata2048 {
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}