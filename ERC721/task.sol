// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    address public _owner;
    uint256 maxsupply = 5000;
    uint256 whitemaxsupply = 1000 ;
    uint256 whitemintid = 0;
    uint256 public tokenprice=0.0001 ether;
    uint256 publicMintFees=0.00001 ether;
    bool public publicMintOpen = true;
    bool public whitelistMintOpen = false;

    mapping(address => bool) public whitelist;

    struct Account {
        address owner;
        uint256 whiteminttoken;
        uint256 publicminttoken;
    }
    mapping(address => Account) public MDAccount;
    

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "localhost:3000";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function editMintWindows() public onlyOwner {
        if(publicMintOpen==true && whitelistMintOpen==false)
        {
            publicMintOpen= false;
            whitelistMintOpen = true;
        }
        else if(publicMintOpen==false && whitelistMintOpen==true)
        {
            whitelistMintOpen = false;
            publicMintOpen= true;
        }
        //  publicMintOpen= _publicMintOpen;
        //  whitelistMintOpen != _whitelistMintOpen;
     }

    function whitelistMint() public payable {
        require(whitelistMintOpen,"WhiteList Mint is Closed");
        require(whitelist[msg.sender],"You are not Whitelisted");
        require(whitemintid <= whitemaxsupply, "White Mint Limit Over");
        require(MDAccount[msg.sender].whiteminttoken<2,"Your white mint limit over, you can use public mint.");
        // require(totalSupply()< maxsupply, "Limit Over");
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        // _safeMint(msg.sender, tokenId);
        internalMint();
        whitemintid++;
        MDAccount[msg.sender].whiteminttoken += 1;
    }

    // Add Payment 
    function publicMint() public payable{
        
        require(publicMintOpen,"Public Mint is Closed");
        //require(msg.value < 0.01 ether, "No Public Mint Available");
        // require(totalSupply()< maxsupply, "Limit Over");
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        // _safeMint(msg.sender, tokenId);
        internalMint();
        MDAccount[msg.sender].publicminttoken += 1;
        (bool sent, bytes memory data) = payable(_owner).call{value: publicMintFees}("");
        //fees(msg.sender);
    }

    function internalMint() internal {
        require(totalSupply()< maxsupply, "Limit Over");
        require(msg.value == tokenprice, "Please Enter Correct Value to mint token");
        require((MDAccount[msg.sender].whiteminttoken + MDAccount[msg.sender].publicminttoken)<10,"Your mint limit over");
        MDAccount[msg.sender].owner = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    
    function setWhitelist(address  addresses) public onlyOwner {
        // for(uint256 i=0; i < addresses.length; i++){
            whitelist[addresses]= true;
        // }
    }

    function removeWhitelist(address[] calldata addresses) public onlyOwner {
        for(uint256 i=0; i < addresses.length; i++){
            whitelist[addresses[i]]= false;
        }
    }

    function changemaxsupply(uint256 maxi) public onlyOwner {
        maxsupply = maxi;
    }

    function changemaxWhitemint(uint256 max) public onlyOwner {
        whitemaxsupply = max;
    }

    function changeTokenPrice(uint256 price) public onlyOwner {
        tokenprice = price;
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
}
