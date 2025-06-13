angular.module('genie').controller('envFormController', function($scope, $http, $rootScope, sessionService, toaster, $location, $state, $timeout) {
    $scope.genieUrl = $rootScope.fileData.backend_url;
    $scope.userEmail = sessionService.getUserId();
    $scope.firstTimeLogin = sessionService.getFirstTimeLogin();
    $scope.selectedDataBaseManagementSystem = [];
    
	$scope.currentStep = 1;
	$scope.totalSteps = 5;
	$scope.showNextButton = false; // Flag to show/hide the bottom "Next" button
	$scope.allStepsCompleted = false; // Flag to show all steps
	
	$scope.nextStep = function() {
		
		$scope.showDbmsError = false;
		$scope.showDbUserError = false;
		$scope.showDbPasswordError = false;
		$scope.showDbHostError = false;
		$scope.showDbPortError = false;
		$scope.showDatabaseError = false;

		// Validation for Step 1
		if ($scope.currentStep === 1 && !$scope.dbms) {
			$scope.showDbmsError = true;
			return;
		}
		
		// Validation for Step 2
		if ($scope.currentStep === 2) {
			if (!$scope.dbHost) {
				$scope.showDbHostError = true;
			}
			if (!$scope.dbPort) {
				$scope.showDbPortError = true;
			}
			if (!$scope.database) {
				$scope.showDatabaseError = true;
			}
			if (!$scope.dbHost || !$scope.dbPort || !$scope.database) {
				return;
			}
		}

		// Validation for Step 3
		if ($scope.currentStep === 3) {
			if (!$scope.dbUser) {
				$scope.showDbUserError = true;
			}
			if (!$scope.dbPassword) {
				$scope.showDbPasswordError = true;
			}
			if (!$scope.dbUser || !$scope.dbPassword) {
				return;
			}
		}
		
		if ($scope.currentStep === 4) {
			$scope.showDbUserTablesError = false; // Reset error visibility

			// Split comma-separated input and trim each table name
			var tablesArray = ($scope.databaseTables || '').split(',').map(function(table) {
				return table.trim();
			});

			// Check if any table name is empty
			var hasEmptyTableName = tablesArray.some(function(table) {
				return table === '';
			});

			if (hasEmptyTableName || tablesArray.length === 0) {
				$scope.showDbUserTablesError = true;
				return;
			}
		}


		// Proceed to the next step
		$scope.currentStep++;
		if ($scope.currentStep === $scope.totalSteps) {
			$scope.allStepsCompleted = true;
		}
	};


	$scope.prevStep = function() {
		$scope.currentStep--;
		$scope.allStepsCompleted = false; // Reset when moving back
	};
    
    $scope.databaseManagementSystemOptions = [
        "mssql", "mariadb", "mysql", "oracledb"
    ];

    const dropdownConfigs = [
        { ele: '#dbms', options: $scope.databaseManagementSystemOptions, model: 'selectedselectedDataBaseManagementSystem', placeholder: 'Select Database Manangement System...' }, ];

	dropdownConfigs.forEach(config => {
		const element = document.querySelector(config.ele);

		if (element) {
			VirtualSelect.init({
				ele: config.ele,
				options: config.options,
				multiple: false,
				placeholder: config.placeholder,
				search: false,
			});

			// Bind dropdown value to Angular scope
			element.addEventListener('change', function() {
				if (config.ele === '#dbms') {
					$scope.dbms = this.value; // Bind to the correct model
				}
				$scope.$apply();
			});
		} else {
			console.error(`Element not found for selector: ${config.ele}`);
		}
	});

    // Fetch existing environment configuration
    $scope.loadEnvConfig = function() {
	    $scope.isLoading = true;
        if (!$scope.userEmail) {
            return;
        }
        var getUrl = $scope.genieUrl + '/api/v1/env/get-user?email=' + encodeURIComponent($scope.userEmail);

        $http.get(getUrl)
            .then(function(response) {
                if (response.data) {
                    $scope.dbms = response.data.DB_MS;
                    $scope.dbUser = response.data.DB_USER;
                    $scope.dbPassword = response.data.DB_PASSWORD;
                    $scope.dbHost = response.data.DB_HOST;
                    $scope.dbPort = response.data.DB_PORT;
                    $scope.database = response.data.DB;
					$scope.databaseTables = response.data.DB_TABLES;
					const dbmsDropdown = document.querySelector('#dbms[data-instance="2"]');
					if (dbmsDropdown) {
						dbmsDropdown.setValue(response.data.DB_MS); // VirtualSelect method to update value
					}
                    toaster.pop('success', "", "Configuration loaded successfully.", 3000, 'trustedHtml');
                } else {
	               if(!$scope.firstTimeLogin){
					}else{
						toaster.pop('error', "", "Not able to load the Configuration.", 3000, 'trustedHtml');
					}
				}
				$scope.isLoading = false;
			})
			.catch(function(error) {
				if (typeof $scope.firstTimeLogin === 'undefined') {
					$state.go('login');
				} else if (!$scope.firstTimeLogin) {
					toaster.error('Error', 'Failed to load configuration.');
					$scope.isLoading = false;
				} else {

				}

			});
	};

    // Save environment configuration
    $scope.saveEnvConfig = function() {
		if ($scope.firstTimeLogin) {
			const selectedDBMS = document.querySelector('#dbms').value; 
		    $scope.dbms = selectedDBMS;
		} else {
            const selectedDBMS = document.querySelector('#dbms[data-instance="2"]').value; 
			$scope.dbms = selectedDBMS;
		}
		
		var envConfigData = {
			email: $scope.userEmail,
			DB_MS: $scope.dbms,
			DB_USER: $scope.dbUser,
			DB_PASSWORD: $scope.dbPassword,
			DB_HOST: $scope.dbHost,
			DB_PORT: parseInt($scope.dbPort, 10),
			DB: $scope.database,
			DB_TABLES: $scope.databaseTables.split(',').map(function(table) {
            return table.trim();  // Create an array of trimmed table names
        	}) 
        };
        
        var httpReq = {
            method: 'PUT',
            url: $scope.genieUrl + '/api/v1/env/user',
            data: envConfigData,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        $http(httpReq)
            .then(function(response) {
                toaster.success('Success', 'Configuration saved successfully.');
            })
            .catch(function(error) {
                toaster.error('Error', 'Failed to save configuration. Please try again.');
            });
          $scope.showNextButton = true;
    };
    
     $scope.navigateToChatbot = function() {
	    $state.go('chatbot');
    };
    
     angular.element(document).ready(function () {
        $scope.loadEnvConfig();
    });
});
