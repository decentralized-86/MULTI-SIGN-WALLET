// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
/* ERRORS */
error OwnerOnlyORuniqueOwner();
error TransactionDoesNotExists();
error TransactionApproved();
error TransactionExecuted();
error NoOfApprovalsCantBeZero();
error InvalidAddress();
error NotEnoughApprovals();
error TransactionFailed();
error TransactionNotApproved();

/** contracts */
contract MultiSignWallet {
    /* Events */
    event Submitted(uint TransactionId);
    event Approved(uint TransactionId,address ApprovedFrom);
    /* Structs */
    struct Transaction {
        address to;
        uint amount;
        bytes data;
        bool executed;
    }
    /* Local Variables */

    mapping(address => bool) isOwner;
    mapping(uint => mapping(address => bool)) approved;
    uint private immutable required;
    Transaction[] transactions;
    address[] owners;

    /* Modifiers */
    modifier OnlyOwner() {
        if (!isOwner[msg.sender]) revert OwnerOnlyORuniqueOwner();
    }
    modifier TxExists(uint _txId) {
        if (_txId >= Transaction.length) revert TransactionDoesNotExists();
    }
    modfier NotApproved(uint _txId) {
        if(approved[_txId][msg.sender]) revert TransactionApproved();
    }
    modifier NotExecuted(uint _txId){
        if(transactions[_txId].executed) revert TransactionExecuted();
    }
    /**
     * @dev Constructor
     * @param _owners:array of owners address 
     * _required: no of Approvals required 
    */
    constructor(address[] calldata _owners,uint _required){
        if(_required <= 0 && _owners.length > _required) revert NoOfApprovalsCantBeZero();
        for(uint i=0;i<_owners.length;i++){
            address owner = _owners[i];
            if(owner == address(0)) revert InvalidAddress();
            if(isOwner[owner]) revert OwnerOnlyORuniqueOwner();
            isOwner[owner] = true;
            owners.push(owner)
        }
        required = _required;
    }

    /**
     * @dev Submit
     * @param _from : address of receiver
     * _amount : amount to be transferred
     * _data : data in bytes
     * 
     */
    function Submit(address _to,uint _amount,bytes calldata _data) external {
        transactions.push(Transaction({
            to:_to,
            amount:_amount,
            data:_data,
            executed:false,
        }))
        emit Submited(transactions.length-1);
    }

    /**
     * @dev Approve
     * @param _txId : The Transaction Id
     */
    function Approve(uint _txId) OnlyOwner() TxExists(_txId) NotApproved(_txId) external {
        approved[_txId][msg.sender] = true;
        emit Approved(_txId,msg.sender);
    }
    /**
     * @dev Execute
     * @param _txId : The Transaction Id
     */
    function Execute(uint _txId) external {
        if(GetApprovalCount(_txId) < required) revert NotEnoughApprovals();
        Transaction storage transaction1 = transactions[_txId];
        transaction1.executed = true;
        (bool success,) = transaction1.to.call{value: transaction1.amount}(transaction1.data); 
        if(!success) revert TransactionFailed();
    }
    /**
     * @dev Revoke
     * @param 
     */
    function Revoke(uint _txId)  TxExists(_txId) NotExecuted(_txId)    external {
        if(!approved[_txId][msg.sender]) revert TransactionNotApproved();
        approved[_txId][msg.sender] = false;
    }
    
    
    /**
     * @dev GetApprovalcount
     * @param _txId : The Transaction Id
     */
    function GetApprovalCount(uint _txId) public view returns(uint count){
        for(uint i=0;i<owners.length;i++){
            if(approved[_txId][msg.sender])
                count++;
        }
    }
}
