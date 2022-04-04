// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    mapping(uint256 => address) public tokens;
    uint256 nftPrice = 0.1 ether; // Mock marketplace, so everything costs the same

    // Mock marketplace so we're not actually going to transfer anything between addresses
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.1 ether!");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns(uint256) {
        return nftPrice;
    }

    // Return true if the referenced NFT is not owned by anybody
    function available(uint256 _tokenId) external view returns(bool) {
        return tokens[_tokenId] == address(0);
    }
}