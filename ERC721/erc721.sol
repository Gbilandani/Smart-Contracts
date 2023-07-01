// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Erc721 is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    uint256 maxSupply = 5000;
    uint256 maxMint = 1000;
    bool WhiteListed = false;
    bool PublicMinted = false;
    uint256 totalmint_user = 10;
    uint256 whitelistmintstatus=0;
    uint256 publiclistmintstatus=0;
    uint256 whitemintid = 0;
    uint256 isWhiteListed;
    uint256 publicMintFees;
    bool public publicMintOpen = true;
    bool public whitelistMintOpen = false;

    mapping(address => uint256) public usertokens;

    struct user {
        address owner;
        uint256 whiteminttoken;
        uint256 publicminttoken;   
    }

    mapping(address=>bool) public whitelist;
    mapping(address=>user) public MDAccount;
    mapping(address => uint256) public publicmint;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("erc721", "we3") {}

    function _baseURI() internal pure override returns (string memory) {
        return "localhost:3000";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function WhiteListMint() public payable {
        require(WhiteListed == true,"user is not whitelisted");
        require(MDAccount[msg.sender].whiteminttoken<2,"Your white mint limit over");
        require(totalSupply() < maxMint,"max mint reached");
        internalMint();
        whitemintid++;
        MDAccount[msg.sender].whiteminttoken += 1;
    }

    function activewhite() public {
        WhiteListed = true;
        PublicMinted = false;
    }

    function publicMint() public payable {
        require(msg.value >= 0.00001 ether,"not enough funds");
        require(totalSupply() < maxSupply,"we sold that");
        internalMint();
    }

    function internalMint() internal {
        
        require(usertokens[msg.sender] < totalmint_user, "Max tokens per user reached");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    } 

    function publicwhite() public {
        WhiteListed = false;
        PublicMinted = true;
    }


    function addWhiteList(address _whiteListAddress) public onlyOwner {
       whitelist[_whiteListAddress] = true;
    }

    function deleteWhiteList(address _deleteAddress) public onlyOwner {
        delete whitelist[_deleteAddress];
    }

    function setMaxSupply(uint _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintFees(uint _mintFees) public onlyOwner {
        publicMintFees = _mintFees;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setWhitelist(address  addresses) public onlyOwner {
        // for(uint256 i=0; i < addresses.length; i++){
            whitelist[addresses]= true;
        // }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function addwhite(address ac_id) public {
        whitelist[ac_id] = true;
    }
}