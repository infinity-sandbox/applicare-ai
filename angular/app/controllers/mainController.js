angular.module('genie')
	.controller('MainController', ['$scope', '$location', 'sessionService', '$document', '$rootScope', 'toaster','$state',  function($scope, $location, sessionService, $document, $rootScope, toaster, $state) {
		const vm = this;
		vm.isMenuClosed = true;
		vm.isUserMenuOpen = false;
		vm.isMenuDropdownOpen = false;
		$scope.userRoles = []; 
		var userId = sessionService.getUserId();
		var sessionId = sessionService.getSessionId();
		
		vm.toggleMenu = function() {
			vm.isMenuClosed = !vm.isMenuClosed;
		};
		
		vm.isLoginPage = function() {
			return $state.current.name === 'login';
		};

		vm.logout = function() {
			vm.isUserMenuOpen = false;
			sessionService.clearSession();
			$rootScope.userEmail = null;
    		$rootScope.userRoles = [];
    		$state.go('login');
		};
		
		$rootScope.$watch('userRoles', function (newRoles) {
            if (newRoles) {
                $scope.userRoles = newRoles;
            }
        });
        $rootScope.$watch('userEmail', function (newEmail) {
            if (newEmail) {
                $scope.userEmail = newEmail;
            }
        });
		
		vm.genieConfig = function () {
            vm.isMenuDropdownOpen = false; // Close the dropdown menu
			if (!$scope.firstTimeLogin) {
				$state.go('environmentForm');
			} else {
				$state.go('login');
			}
         /*  if ($scope.userRoles.includes('ROLE_ADMIN')) {
                // Redirect to admin form if ROLE_ADMIN exists
                $state.go('environment-admForm');
            } else if ($scope.userRoles.includes('ROLE_USER')) {
                // Redirect to user form if only ROLE_USER exists
                $state.go('environment-form');
            } else {
                // Fallback case if no roles are found
                console.error('No valid roles detected. Redirecting to login.');
                $state.go('login');
            } */
        };

		vm.toggleUserMenu = function() {
			vm.isUserMenuOpen = !vm.isUserMenuOpen;

			if (vm.isUserMenuOpen) {
				$document.on('click', handleClickOutside);
			} else {
				$document.off('click', handleClickOutside);
			}
		};

		function handleClickOutside(event) {
			var userMenuElement = document.querySelector('.user-menu');
			if (userMenuElement && !userMenuElement.contains(event.target)) {
				$scope.$apply(function() {
					vm.isUserMenuOpen = false;
				});
				$document.off('click', handleClickOutside);
			}
		}

		$scope.$watch(function() {
			return sessionService.getUserId();
		}, function(newVal) {
			if (newVal) {
				vm.userId = newVal.charAt(0).toUpperCase(); 
			}
		});
		
		vm.toggleMenuDropdown = function() {
			vm.isMenuDropdownOpen = !vm.isMenuDropdownOpen;

			if (vm.isMenuDropdownOpen) {
				$document.on('click', handleDropdownClickOutside);
			} else {
				$document.off('click', handleDropdownClickOutside);
			}
		};

		function handleDropdownClickOutside(event) {
			const menuButtonElement = document.querySelector('.menu-button');
			const isClickInside = menuButtonElement && menuButtonElement.contains(event.target);

			if (!isClickInside) {
				$scope.$apply(() => {
					vm.isMenuDropdownOpen = false;
				});
				$document.off('click', handleDropdownClickOutside);
			}
		}

	}]);
