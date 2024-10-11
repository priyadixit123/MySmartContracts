// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmployeeRating {
    
    struct Employee {
        string name;

        uint totalRating;  // Sum of all ratings received
        uint ratingCount;   // Number of ratings received

    }
     // Mapping to track who rated whom (prevents double rating)
    mapping (address => mapping (uint => bool)) public ratedList;

    // Mapping to store employees
    mapping(address => Employee) public employees;
    mapping (address => mapping (address => bool)) public hasRated;
    

    // List of all employee addresses
    address[] public employeeList;

     // Event when a new rating is given
    event RatingGiven (address indexed employee, address indexed rater, uint256 rating);

    // Function to add an employee (anyone can add an employee)
    function addEmployee(string memory _name) public {
    require(bytes(employees[msg.sender].name).length == 0, "Already registered!");
     employees[msg.sender] = Employee ({
        name : _name,
        totalRating : 0,
        ratingCount : 0
     });

     employeeList.push(msg.sender);
  
  }

  // Function to rate an employee (1 to 5 stars)
  function rateEmployee (address _employee, uint256 _rating ) public {

    require(_rating >=1 && _rating <=5, "Invalid rating");
    require(bytes(employees[_employee].name).length > 0, "Employee not registered");
    require(!hasRated[msg.sender][_employee], "you are already rated this employee");
     employees[_employee].totalRating += _rating;
     employees[_employee].ratingCount += 1;

     hasRated[msg.sender][_employee] = true;

     emit RatingGiven(_employee, msg.sender, _rating);
  
  }

  function getEmployeeRating(address _employee) public view returns(uint256 )
  {
    Employee storage employee = employees[_employee];
    require(employee.ratingCount > 0 , "no ratings found");
    return employee.totalRating / employee.ratingCount ;
  }

  function getBestEmployee() public view returns (address,string memory , uint256){
     
    address bestEmployee = address(0);
    uint256 highestRating = 0;
    for (uint i = 0 ; i < employeeList.length ; i++)  // 1 to employees.length - 1 
    {
        address employeeAddr = employeeList[i];
        Employee storage employee = employees[employeeAddr];
        
        if (employee.ratingCount > 0){ 
            uint256 averageRating = employee.totalRating / employee.ratingCount ;// if the employee is not address(0) and if the employee is not the best employee
              // if the employee hasnt rated the best employee
                if(averageRating > highestRating) {
                highestRating = averageRating;
                bestEmployee = employeeAddr; // update bestEmployee to employeeList[i] if the avarage rating is greater than the highest rating
            }
        }
    }
        require(bestEmployee != address(0), "no employee found");
        return(bestEmployee, employees[bestEmployee].name, highestRating);
}
   // Function to get the list of all employees
 function getAllEmployees()public view returns (address[] memory) {

    return employeeList;
 }
 
 }
