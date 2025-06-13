angular.module('genie')
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {
        
        // Default route if none matches
        $urlRouterProvider.otherwise('/login');

        // Define states using $stateProvider with named views
        $stateProvider
            .state('login', {
                url: '/login',
                views: {
                    'loginView': {
                        templateUrl: 'app/views/login.html',
                        controller: 'loginController',
                        controllerAs: 'loginCtrl'
                    }
                }
            })
            .state('chatbot', {
                url: '/chatbot',
                views: {
                    'mainView': {
                        templateUrl: 'app/views/home.html',
                        controller: 'homeController',
                        controllerAs: 'homeCtrl'
                    }
                }
            })
            .state('environmentForm', {
                url: '/environmentform',
                views: {
                    'mainView': {
                        templateUrl: 'app/views/envForm.html',
                        controller: 'envFormController',
                        controllerAs: 'envCtrl'
                    }
                }
            })
            .state('environmentadmform', {
                url: '/environmentadmform',
                views: {
                    'mainView': {
                        templateUrl: 'app/views/envaForm.html',
                        controller: 'envaFormController',
                        controllerAs: 'envadmCtrl'
                    }
                }
            });
    }])
    .run(['$rootScope', '$http', function($rootScope, $http) {
        $http.get('/genie/readFile')
            .then(function(response) {
                $rootScope.fileData = response.data;
            })
            .catch(function(error) {
                console.error("Error loading file data:", error);
                $rootScope.fileData = {};
            });
    }]);
