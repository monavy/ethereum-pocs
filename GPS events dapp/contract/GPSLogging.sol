pragma solidity ^0.4.0;

contract LoggingGPS {
    event GPSPosition(address from, uint256 blockNumber, uint256 timestamp, bytes32  lat, bytes32  lon, bytes32  speed);


    function storePosition(bytes32  lat, bytes32  lon, bytes32  speed) public {
        GPSPosition(msg.sender, block.number, block.timestamp, lat, lon, speed);
    }
}