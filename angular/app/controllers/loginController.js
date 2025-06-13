angular.module('genie').controller('loginController', function($scope, $http, $location, $window, sessionService, $rootScope, $httpParamSerializer, $state) {
	var that = this;
	$scope.isLoading = false;
    $scope.loginApiUrl = null;
    $scope.genieUrl = null;
    $scope.firstTimeLogin = true;

	this.checkLoginDetails = function () {
    if (!$scope.loginApiUrl) {
        $scope.errorMessage = "Login URL is not available. Please contact support.";
        return;
    }

    $scope.isLoading = true;
    $scope.showError = false;

    // const loginData = {
    //     email: $scope.genieuserID,
    //     password: $scope.geniepassword,
    //     spec: "genie"
    // };
	const loginData = `username=${encodeURIComponent($scope.genieuserID)}&password=${encodeURIComponent($scope.geniepassword)}`;

		// Wait for `checkFirstTimeLogin` to complete before proceeding
		$scope.checkFirstTimeLogin()
			.then(() => {
				//const serializedData = $httpParamSerializer(loginData);

				return $http.post('http://0.0.0.0:8000/api/v1/auth/login', loginData, {
					headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
				});
			})
			.then(function successCallback(response) {
				var sessionId = generateSessionID();
				sessionService.setUserId($scope.genieuserID);
				$scope.isLoading = false;
				if (response.status === 200) {
					// $rootScope.userRoles = response.data.roles;
					// $rootScope.userEmail = response.data.email;

					sessionService.setAccessToken(response.data.access_token);
                	sessionService.setRefreshToken(response.data.refresh_token);

					sessionService.setFirstTimeLogin($scope.firstTimeLogin);

					if (sessionService.getFirstTimeLogin()) {
						$state.go('environmentForm');
					} else {
						$state.go('chatbot');
					}
				}
			})
			.catch(function errorCallback(error) {
				$scope.isLoading = false;
				$scope.showError = true;
				$scope.errorMessage = error.status === 400 && error.data.detail === "Invalid credentials"
					? "Username or password is incorrect."
					: "Unable to connect to the server. Please check your network.";
			});
	};

	$scope.checkFirstTimeLogin = function() {
		return new Promise((resolve, reject) => {
			if (!$scope.genieuserID) {
				resolve();
				return;
			}

			const getUrl = $scope.genieUrl + '/api/v1/env/get-user?email=' + encodeURIComponent($scope.genieuserID);

			$http.get(getUrl)
				.then(function(response) {
					if (response.data) {
						$scope.dbms = response.data.DB_MS;
						$scope.dbUser = response.data.DB_USER;
						$scope.dbPassword = response.data.DB_PASSWORD;
						$scope.dbHost = response.data.DB_HOST;
						$scope.dbPort = response.data.DB_PORT;
						$scope.database = response.data.DB;
						$scope.checkLogin = false;
						$scope.firstTimeLogin = $scope.checkLogin;
					}
					resolve(); 
				})
				.catch(function(error) {
					$scope.checkLogin = true;
					$scope.firstTimeLogin = $scope.checkLogin;
					resolve(); 
				});
		});
	};

    function generateSessionID() {
		var today = new Date();
		var day = String(today.getDate()).padStart(2, '0');
		var month = String(today.getMonth() + 1).padStart(2, '0');
		var year = today.getFullYear();
		var todayKey = `${day}-${month}-${year}`;

		// Retrieve the last sessionId and split to check the date
		let lastSessionId = localStorage.getItem('sessionId');
		let lastDate = lastSessionId ? lastSessionId.split('-system_')[0] : null;
		let sessionCount = 0;

		if (lastDate === todayKey) {
			// Increment if the session is for the same day
			sessionCount = parseInt(lastSessionId.split('-system_')[1] || 0) + 1;
		}

		// Generate new sessionId
		let newSessionId = `${todayKey}-system_${sessionCount}`;

		// Update localStorage
		localStorage.setItem('sessionId', newSessionId);

		return newSessionId;
	}
	
	function fetchLoginUrl() {
        if (!$rootScope.fileData) {
            $rootScope.fileData = {}; // Ensure fileData is initialized
        }

        if (!$rootScope.fileData.backend_url) {
            $http.get('/genie/readFile')
                .then(function(response) {
                    $rootScope.fileData = response.data || {};
                    $scope.loginApiUrl = $rootScope.fileData.backend_url || '';
                    $scope.genieUrl = $rootScope.fileData.backend_url || '';
                })
                .catch(function(error) {
                    console.error("Error loading file data:", error);
                    $rootScope.fileData = {}; // Fallback to empty object
                });
        } else {
            $scope.loginApiUrl = $rootScope.fileData.backend_url;
            $scope.genieUrl = $rootScope.fileData.backend_url;
        }
    }
    
    angular.element(document).ready(function () {
        fetchLoginUrl();
    });
});
