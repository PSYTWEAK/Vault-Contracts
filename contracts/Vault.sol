pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./INFT.sol";
import "./VerifySignature.sol";

/* 
Yb    dP    db    88   88 88     888888 
 Yb  dP    dPYb   88   88 88       88   
  YbdP    dP__Yb  Y8   8P 88  .o   88   
   YP    dP""""Yb `YbodP' 88ood8   88  
*/

contract Vault is ERC721Enumerable, Ownable, VerifySignature {
    /*  
    ================================================================
                            State 
    ================================================================ 
    */

    INFT public NFTContract;

    uint256 public unlockDelay = 0;

    uint256 public timeUntilUnlockExpires = 1 minutes;

    mapping(uint256 => uint256) timeUntilSingleNFTUnlocked;

    uint256 public timeUntilAllUnlocked;

    address public backupAddressForEmergency;

    bool public hasOwner;

    /*  
    ================================================================
                            Contructor 
    ================================================================ 
    */

    constructor(address contractAddr, address _backupAddressForEmergency)
        ERC721(
            string(abi.encodePacked("locked", INFT(contractAddr).name())),
            string(abi.encodePacked("locked", INFT(contractAddr).symbol()))
        )
    {
        NFTContract = INFT(contractAddr);
        backupAddressForEmergency = _backupAddressForEmergency;
    }

    /*  
    ================================================================
                    Only owner external Functions 
    ================================================================ 
    */

    function unlock(uint256 tokenId) external onlyOwner {
        timeUntilSingleNFTUnlocked[tokenId] = block.timestamp + unlockDelay;
    }

    function unlockAll() external onlyOwner {
        timeUntilAllUnlocked = block.timestamp + unlockDelay;
    }

    function withdraw(uint256 tokenId)
        public
        onlyOwner
        checkIsUnlocked(tokenId)
    {
        burnDummyNFT(tokenId);
        NFTContract.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawMultiple(uint256[] memory tokenId) external onlyOwner {
        for (uint256 i; i < tokenId.length; i++) {
            withdraw(tokenId[i]);
        }
    }

    function deposit(uint256 tokenId) external onlyOwner {
        transferNFT(tokenId);
        mintDummyNFT(tokenId);
    }

    /*  
    ================================================================
            Emergency Owner and Backup address Functions 
    ================================================================ 
    */

    function withdrawAccidentalWrongNFTDeposit(
        address NFTaddress,
        uint256 tokenId
    ) external onlyOwner {
        INFT(NFTaddress).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function acceptEmergencyInviteForBackupAddressToTakeControl(
        bytes memory signature
    ) external onlyBackupAddress checkValidSignature(signature) {
        _transferOwnership(backupAddressForEmergency);
    }

    function transferOwnership(address owner) public override onlyOwner {
        require(!hasOwner, "Vault: Owner already set on creation");
        _transferOwnership(owner);
        hasOwner = true;
    }

    /*  
    ================================================================
                            Modifers 
    ================================================================ 
    */

    modifier checkIsUnlocked(uint256 tokenId) {
        if (!isTokenUnlocked(tokenId)) {
            require(isAllTokensUnlocked(), "Vault: Token is locked");
        }
        _;
    }

    modifier onlyBackupAddress() {
        require(
            backupAddressForEmergency == msg.sender,
            "Vault: this address is not the back up account"
        );
        _;
    }

    modifier checkValidSignature(bytes memory signature) {
        string memory message = "Invite";
        require(
            verify(owner(), backupAddressForEmergency, message, signature),
            "Vault: Signature is invalid"
        );
        _;
    }

    /*  
    ================================================================
                            Internal Functions 
    ================================================================ 
    */

    function isTokenUnlocked(uint256 tokenId) internal returns (bool) {
        uint256 timeUnlocked = timeUntilSingleNFTUnlocked[tokenId];
        uint256 timeUnlockExpires = timeUntilSingleNFTUnlocked[tokenId] +
            timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function isAllTokensUnlocked() internal returns (bool) {
        uint256 timeUnlocked = timeUntilAllUnlocked;
        uint256 timeUnlockExpires = timeUntilAllUnlocked +
            timeUntilUnlockExpires;
        return (block.timestamp >= timeUnlocked &&
            block.timestamp < timeUnlockExpires);
    }

    function burnDummyNFT(uint256 tokenId) internal {
        if (ownerOf(tokenId) == msg.sender) {
            _burn(tokenId);
        }
    }

    function mintDummyNFT(uint256 tokenId) internal {
        _mint(msg.sender, tokenId);
    }

    function transferNFT(uint256 tokenId) internal {
        if (NFTContract.ownerOf(tokenId) != address(this)) {
            NFTContract.safeTransferFrom(msg.sender, address(this), tokenId);
        }
    }

    /*  
    ================================================================
                        Public View Functions 
    ================================================================ 
    */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return NFTContract.tokenURI(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
