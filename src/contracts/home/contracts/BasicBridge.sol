pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BasicBridge {
    uint32 constant internal UPPER_BOUND = 0xffffffff;

    event EpochEnd(uint16 indexed epoch);
    event EpochClose(uint16 indexed epoch);
    event ForceSign();
    event NewEpoch(uint16 indexed oldEpoch, uint16 indexed newEpoch);
    event NewEpochCancelled(uint16 indexed epoch);
    event NewFundsTransfer(uint16 indexed oldEpoch, uint16 indexed newEpoch);
    event EpochStart(uint16 indexed epoch, uint x, uint y);

    struct State {
        address[] validators;
        uint32 startBlock;
        uint32 endBlock;
        uint32 nonce;
        uint16 threshold;
        uint16 rangeSize;
        uint96 minTxLimit;
        uint96 maxTxLimit;
        bool closeEpoch;
        uint x;
        uint y;
    }

    enum Status {
        READY, // bridge is in ready to perform operations
        CLOSING_EPOCH, // generating transaction for blocking binance side of the bridge
        VOTING, // voting for changing in next epoch, but still ready
        KEYGEN, //keygen, can be cancelled
        FUNDS_TRANSFER // funds transfer, cannot be cancelled
    }

    mapping(uint16 => State) public states;

    Status public status;

    uint16 public epoch;
    uint16 public nextEpoch;

    IERC20 public tokenContract;

    modifier ready {
        require(status == Status.READY, "Not in ready state");
        _;
    }

    modifier closingEpoch {
        require(status == Status.CLOSING_EPOCH, "Not in closing epoch state");
        _;
    }

    modifier voting {
        require(status == Status.VOTING, "Not in voting state");
        _;
    }

    modifier keygen {
        require(status == Status.KEYGEN, "Not in keygen state");
        _;
    }

    modifier fundsTransfer {
        require(status == Status.FUNDS_TRANSFER, "Not in funds transfer state");
        _;
    }

    function getParties() public view returns (uint16) {
        return getParties(epoch);
    }

    function getNextParties() public view returns (uint16) {
        return getParties(nextEpoch);
    }

    function getParties(uint16 _epoch) public view returns (uint16) {
        return uint16(states[_epoch].validators.length);
    }

    function getThreshold() public view returns (uint16) {
        return getThreshold(epoch);
    }

    function getNextThreshold() public view returns (uint16) {
        return getThreshold(nextEpoch);
    }

    function getThreshold(uint16 _epoch) public view returns (uint16) {
        return states[_epoch].threshold;
    }

    function getStartBlock() public view returns (uint32) {
        return getStartBlock(epoch);
    }

    function getStartBlock(uint16 _epoch) public view returns (uint32) {
        return states[_epoch].startBlock;
    }

    function getRangeSize() public view returns (uint16) {
        return getRangeSize(epoch);
    }

    function getNextRangeSize() public view returns (uint16) {
        return getRangeSize(nextEpoch);
    }

    function getMinPerTx() public view returns (uint96) {
        return getMinPerTx(epoch);
    }

    function getNextMinPerTx() public view returns (uint96) {
        return getMinPerTx(nextEpoch);
    }

    function getMinPerTx(uint16 _epoch) public view returns (uint96) {
        return states[_epoch].minTxLimit;
    }

    function getMaxPerTx() public view returns (uint96) {
        return getMaxPerTx(epoch);
    }

    function getNextMaxPerTx() public view returns (uint96) {
        return getMaxPerTx(nextEpoch);
    }

    function getMaxPerTx(uint16 _epoch) public view returns (uint96) {
        return states[_epoch].maxTxLimit;
    }

    function getRangeSize(uint16 _epoch) public view returns (uint16) {
        return states[_epoch].rangeSize;
    }

    function getNonce() public view returns (uint32) {
        return getNonce(epoch);
    }

    function getNonce(uint16 _epoch) public view returns (uint32) {
        return states[_epoch].nonce;
    }

    function getX() public view returns (uint) {
        return getX(epoch);
    }

    function getX(uint16 _epoch) public view returns (uint) {
        return states[_epoch].x;
    }

    function getY() public view returns (uint) {
        return getY(epoch);
    }

    function getY(uint16 _epoch) public view returns (uint) {
        return states[_epoch].y;
    }

    function getCloseEpoch() public view returns (bool) {
        return getCloseEpoch(epoch);
    }

    function getNextCloseEpoch() public view returns (bool) {
        return getCloseEpoch(nextEpoch);
    }

    function getCloseEpoch(uint16 _epoch) public view returns (bool) {
        return states[_epoch].closeEpoch;
    }

    function getNextPartyId(address a) public view returns (uint16) {
        address[] memory validators = getNextValidators();
        for (uint i = 0; i < getNextParties(); i++) {
            if (validators[i] == a)
                return uint16(i + 1);
        }
        return 0;
    }

    function getValidators() public view returns (address[] memory) {
        return getValidators(epoch);
    }

    function getNextValidators() public view returns (address[] memory) {
        return getValidators(nextEpoch);
    }

    function getValidators(uint16 _epoch) public view returns (address[] memory) {
        return states[_epoch].validators;
    }
}
