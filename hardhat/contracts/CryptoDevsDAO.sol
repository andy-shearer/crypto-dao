// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoDevsDAO is Ownable {

    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 votesY;
        uint256 votesN;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        Yes,
        No
    }

    mapping (uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    // Constructor is payable so that we can deploy the contract with funds already in the DAO treasury
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Must own a CryptoDevs NFT to perform this interaction");
        _;
    }

    modifier activeProposalsOnly(uint256 _proposalIndex) {
        require(proposals[_proposalIndex].deadline > block.timestamp, "The deadline for this proposal has passed");
        _;
    }

    modifier inactiveProposalsOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline <= block.timestamp,
            "The deadline for this proposal has not yet been reached"
        );
        require(
            proposals[_proposalIndex].executed == false,
            "This proposal has already been executed"
        );
        _;
    }

    // Creates a new proposal to buy the indicated token, returning the index of the newly created proposal
    function createProposal(uint256 _nftId) external nftHolderOnly returns(uint256) {
        require(nftMarketplace.available(_nftId), "Provided token is not for sale");
        Proposal storage newProposal = proposals[numProposals];
        newProposal.nftTokenId = _nftId;
        newProposal.deadline = block.timestamp + 5 minutes;
        numProposals++;

        return numProposals - 1;
    }

    function voteOnProposal(uint256 _proposalIndex, Vote _vote) external nftHolderOnly activeProposalsOnly(_proposalIndex) {
        Proposal storage targetProposal = proposals[_proposalIndex];
        uint256 voterNFTBal = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 availableVotes = 0;

        // Calculate how many votes this user can make
        // Dependant on how many CryptoDevs NFTs they own, and how many votes they've already made on this proposal
        for(uint256 i = 0; i < voterNFTBal; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(targetProposal.voters[tokenId] == false) {
                // Not yet voted on this proposal using this NFT's allowed vote, so increment availableVotes
                availableVotes++;
                targetProposal.voters[tokenId] = true;
            }
        }
        require(availableVotes > 0, "You have already used all available votes on this proposal");

        if(_vote == Vote.Yes) {
            targetProposal.votesY += availableVotes;
        } else if(_vote == Vote.No) {
            targetProposal.votesN += availableVotes;
        }
    }

    function executeProposal(uint256 _proposalIndex) external nftHolderOnly inactiveProposalsOnly(_proposalIndex) {
        Proposal storage targetProposal = proposals[_proposalIndex];

        if(targetProposal.votesY > targetProposal.votesN) {
            uint256 tokenPrice = nftMarketplace.getPrice();
            require(address(this).balance >= tokenPrice, "DAO treasury has insufficient funds to execute this proposal");
            nftMarketplace.purchase{value: tokenPrice}(targetProposal.nftTokenId);
        }

        targetProposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Allow the contract to receive deposits directly
    receive() external payable {}
    fallback() external payable {}
}