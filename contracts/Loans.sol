pragma solidity >=0.5.0 <0.6.0;

/* 
 * Note: Repayment of the loan is not provided by the terms of reference.
 * Note: Refusal of the loan by the delegate person is also not provided by the terms of reference.
 */

contract Loans {

    address payable public owner;
    mapping (address => uint256) requests;
    mapping (address => uint256) approved;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

	modifier onlyDelegate(bytes32 messageHash) {
		require(addressHash(msg.sender) == messageHash);
		_;
	}
    
	/* Applicant functions */

    function request(uint256 amount) public {
		_request(msg.sender, amount);
    }

    function receiveFunds() public {
		_receiveFunds(msg.sender);
    }

    function rejectFunds() public {
        require(approved[msg.sender] != 0);
        
        uint256 funds = approved[msg.sender];
        approved[msg.sender] = 0;
        owner.transfer(funds);
    }


	/* Delegate functions */

	function delegatedRequest(uint256 amount, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) onlyDelegate(messageHash) public {
		address applicant = recoverApplicant(messageHash, v, r, s);
		_request(applicant, amount);
	}

	function delegatedReceiveFunds(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) onlyDelegate(messageHash) public {
		address applicant = recoverApplicant(messageHash, v, r, s);
		address payable applicantPayable = address(uint160(applicant));
		_receiveFunds(applicantPayable);
	}

	/* Owner functions */

	function TEST_balance(address a) onlyOwner public returns(uint256) {
		return a.balance;
	}

	function approve(address applicant, uint256 amount) onlyOwner payable public {
        require(requests[applicant] != 0);
        require(approved[applicant] == 0);
        
        uint256 approvedAmount;
        
        // Approve the entire amount if the `amount` is not specified
        if (amount == 0) {
            approvedAmount = requests[applicant];
        } else {
            require(amount <= requests[applicant]);
            approvedAmount = amount;
        }
        
        require(msg.value == approvedAmount);
        
        approved[applicant] = approvedAmount;
        requests[applicant] = 0;
    }

    function reject(address applicant) onlyOwner public {
        require(requests[applicant] != 0);
        require(approved[applicant] == 0);
        
        approved[applicant] = 0;
        requests[applicant] = 0;
    }

	function getApproved(address applicant) onlyOwner view public returns(uint256) {
		return approved[applicant];
	}

	function getRequested(address applicant) onlyOwner view public returns(uint256) {
		return requests[applicant];
	}
    
	/* Private functions */

	function _request(address applicant, uint256 amount) private {
        require(amount != 0);
        require(requests[applicant] == 0);
        require(approved[applicant] == 0);
        require(applicant != owner);
        
        requests[applicant] = amount;
	}

	function _receiveFunds(address payable applicant) private {
        require(approved[applicant] != 0);

        applicant.transfer(approved[applicant]);
	}
    
    function recoverApplicant(bytes32 hash, uint8 v, bytes32 r, bytes32 s) private returns (address) {
        return ecrecover(hash, v, r, s);
    }

	function addressHash(address a) private pure returns(bytes32) {
		bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(a))));

    	return hash;
	}

}