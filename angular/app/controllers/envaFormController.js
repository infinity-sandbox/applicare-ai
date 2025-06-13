angular.module('genie').controller('envaFormController', function($scope, $http, $location, $window, sessionService, $state, $timeout, $rootScope, toaster) {
    $scope.genieUrl = $rootScope.fileData.backend_url;
    $scope.admEmail = $rootScope.userEmail;

    $scope.config = {
        email: $scope.admEmail,
        email_user: '',
        DB_MS: '',
        DB_USER: '',
        DB_PASSWORD: '',
        DB_HOST: '',
        DB_PORT: '',
        DB: '',
        MODEL: '',
        OPENAI_API_KEY: '',
        WEAVIATE_URL: '',
        WEAVIATE_API_KEY: '',
        REDIS_HOST: '',
        REDIS_PORT: '',
        MY_EMAIL: '',
        MY_EMAIL_PASSWORD: '',
        EMAIL_APP_PASSWORD: '',
        FRONTEND_API_URL: '',
        BACKEND_API_URL: '',
        REQUESTS_PER_WINDOW: 100,
        TIME_WINDOW: 60,
        ACCESS_TOKEN_EXPIRE_MINUTES: '',
        REFRESH_TOKEN_EXPIRE_MINUTES: '',
        ALGORITHM: '',
        JWT_SECRET_KEY: '',
        JWT_REFRESH_SECRET_KEY: '',
        backendCorsOrigins: '',
        databaseTables: ''
    };

    $scope.allowedMethodsOptions = ["GET", "POST"];
    $scope.restrictedMethodsOptions = ["PUT", "DELETE"];
    $scope.criticalRestrictedMethodsOptions = ["PATCH"];

    $scope.selectedAllowedMethods = [];
    $scope.selectedRestrictedMethods = [];
    $scope.selectedCriticalRestrictedMethods = [];

    const dropdownConfigs = [
        { ele: '#allowedMethods', options: $scope.allowedMethodsOptions, model: 'selectedAllowedMethods', placeholder: 'Select Allowed Methods' },
        { ele: '#restrictedMethods', options: $scope.restrictedMethodsOptions, model: 'selectedRestrictedMethods', placeholder: 'Select Restricted Methods' },
        { ele: '#criticalRestrictedMethods', options: $scope.criticalRestrictedMethodsOptions, model: 'selectedCriticalRestrictedMethods', placeholder: 'Select Critical Restricted Methods' }
    ];

    dropdownConfigs.forEach(config => {
        const element = document.querySelector(config.ele);

        if (element) {
            VirtualSelect.init({
                ele: config.ele,
                options: config.options,
                multiple: true,
                placeholder: config.placeholder,
                search: false,
            });

            element.addEventListener('change', function() {
                $scope[config.model] = this.value; // Update the model
                $scope.$apply();
            });
        } else {
            console.error(`Element not found for selector: ${config.ele}`);
        }
    });

    $scope.saveAdminEnvConfig = function() {
        const payload = {
            email: $scope.admEmail,
            email_user: $scope.config.email_user,
            DB_MS: $scope.config.DB_MS,
            DB_USER: $scope.config.DB_USER,
            DB_PASSWORD: $scope.config.DB_PASSWORD,
            DB_HOST: $scope.config.DB_HOST,
            DB_PORT: parseInt($scope.config.DB_PORT, 10),
            DB: $scope.config.DB,
            MODEL: $scope.config.MODEL,
            OPENAI_API_KEY: $scope.config.OPENAI_API_KEY,
            WEAVIATE_URL: $scope.config.WEAVIATE_URL,
            WEAVIATE_API_KEY: $scope.config.WEAVIATE_API_KEY,
            REDIS_HOST: $scope.config.REDIS_HOST,
            REDIS_PORT: parseInt($scope.config.REDIS_PORT, 10),
            MY_EMAIL: $scope.config.MY_EMAIL,
            MY_EMAIL_PASSWORD: $scope.config.MY_EMAIL_PASSWORD,
            EMAIL_APP_PASSWORD: $scope.config.EMAIL_APP_PASSWORD,
            FRONTEND_API_URL: $scope.config.FRONTEND_API_URL,
            BACKEND_API_URL: $scope.config.BACKEND_API_URL,
            REQUESTS_PER_WINDOW: $scope.config.REQUESTS_PER_WINDOW,
            TIME_WINDOW: $scope.config.TIME_WINDOW,
            ALLOWED_HTTP_REQUEST_METHODS: $scope.selectedAllowedMethods,
            RESTRICTED_HTTP_REQUEST_METHODS: $scope.selectedRestrictedMethods,
            CRITICAL_RESTRICTED_HTTP_REQUEST_METHODS: $scope.selectedCriticalRestrictedMethods,
            backendCorsOrigins: $scope.config.backendCorsOrigins.split(',').map(item => item.trim()),
            DB_TABLES: $scope.config.databaseTables.split(',').map(item => item.trim()),
            ACCESS_TOKEN_EXPIRE_MINUTES: parseInt($scope.config.ACCESS_TOKEN_EXPIRE_MINUTES, 10),
            REFRESH_TOKEN_EXPIRE_MINUTES: parseInt($scope.config.REFRESH_TOKEN_EXPIRE_MINUTES, 10),
            ALGORITHM: $scope.config.ALGORITHM,
            JWT_SECRET_KEY: $scope.config.JWT_SECRET_KEY,
            JWT_REFRESH_SECRET_KEY: $scope.config.JWT_REFRESH_SECRET_KEY
        };

        // Send PUT request
        $http.put($scope.genieUrl + '/api/v1/env/admin', payload)
            .then(response => {
                toaster.pop('success', "", "Environment Configuration saved successfully.", 3000, 'trustedHtml');
            })
            .catch(error => {
                toaster.error('Error', 'Error saving configuration');
            });
    };
});
