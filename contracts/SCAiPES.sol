// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SCAiPES is ERC721, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Link to GCS with metadata
    string baseURI; 

    uint256 maxSupply = 10000;      
    uint256 price = 0.01 ether;
    bool public publicMintOpen = true;
    event mint(uint256 tokenId, address minter, uint256 burnedTokenToCopy);
    
    uint256 burnerPayout = 0.005 ether;
    uint256[] burnedTokenIds;
    mapping(uint256 => address) public burnerAddresses;
    event burn(uint256 tokenId, address burner);

    constructor() ERC721("SCAiPES", "SCAiPES") {
        // Start token IDs from 1
        _tokenIdCounter.increment();
    }
  
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {        
        return baseURI;
    }

    // Open or close minting
    function editMintWindows(bool open) external onlyOwner{
        publicMintOpen = open;
    }

    // Mint a new token
    function publicMint(uint256 burnedTokenToCopy) public payable {
        // Checks that minting is open
        require(publicMintOpen, "Public Mint is Closed");

        // Make sure user is either generating a new image, or copying a burned image
        // if burnerAddresses[burnedTokenToCopy] == address(0), then that token has not been burned
        require(
            burnedTokenToCopy == 0 || burnerAddresses[burnedTokenToCopy]!= address(0), 
            "You can only copy a token that has been burned"
        );

        // Checks that the user has sent enough ETH to purchase token
        require(msg.value >= price, "You have not sent enough ETH to purchase a token");

        uint256 tokenId = internalMint();

        // If user is minting a copy of a burned token, send the burnPayout amount to the original burner
        if(burnedTokenToCopy!= 0){
            payable(burnerAddresses[burnedTokenToCopy]).transfer(burnerPayout);
        }

        // Emit mint event so backend can generate metadata
        emit mint(tokenId, msg.sender, burnedTokenToCopy);

    }

    // Internal mint function used by publicMint
    function internalMint() internal returns(uint256) {
        // Checks that the max supply has not been reached
        require(totalSupply() < maxSupply, "Sorry, We are Sold out!!!");

        // Get the current tokenId and update counter
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(msg.sender, tokenId);

        return tokenId;  
    }

    function burnToken(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner of this token or approved");

        // Burn the token by sending to zero address
        _burn(tokenId);

        // Add address of user who burned to burner addresses for use in revenue share
        burnerAddresses[tokenId] = msg.sender;

        // Add token to list of burned tokens for use on front-end gallery page
        burnedTokenIds.push(tokenId);

        // Emit burn event so backend can update metadata of burned token
        emit burn(tokenId, msg.sender);
    } 

    // Returns list of burned token IDs to display on gallery page
    function getBurntTokenIds() public view returns(uint256[] memory){ 
        return burnedTokenIds;
    }

    // Withdraw ETH earned from minting
    function withdraw(address addr) external onlyOwner{
        uint256 balance = address(this).balance;
        payable(addr).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
