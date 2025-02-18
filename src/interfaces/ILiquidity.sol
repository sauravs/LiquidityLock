
pragma solidity 0.8.24;

interface ILiquidity {
    function initialize(address _owner, uint256 _tokenId, uint256 _unlockTime) external;

    function withdraw(address nftContract, uint256 tokenId) external;

    function getOwner() external view returns (address);
    function getTokenId() external view returns (uint256);
    function getUnlockTime() external view returns (uint256);
}