{
    inputs =
        {
            bash_unit-checker-lib.url = "github:viktordanek/bash_unit-checker" ;
            environment-variable-lib.url = "github:viktordanek/environment-variable" ;
            flake-utils.url = "github:numtide/flake-utils" ;
            has-standard-input-lib.url = "github:viktordanek/has-standard-input" ;
            invalid-value-lib.url = "github:viktordanek/invalid-value" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
            strip-lib.url = "github:viktordanek/strip" ;
            temporary-lib.url = "github:viktordanek/temporary" ;
        } ;
    outputs =
        { bash_unit-checker-lib , environment-variable-lib , flake-utils , has-standard-input-lib , invalid-value-lib , nixpkgs , self , strip-lib , temporary-lib } :
            let
                fun =
                    system :
                        let
                            bash_unit-checker = builtins.getAttr system ( builtins.getAttr "lib" bash_unit-checker-lib ) ;
                            environment-variable = builtins.getAttr system ( builtins.getAttr "lib" environment-variable-lib ) ;
                            invalid-value = builtins.getAttr system ( builtins.getAttr "lib" invalid-value-lib ) ;
                            lib =
                                {
                                    injection ,
                                    invalid-text-value ? invalid-value "3f51c04b772067c290e86dcfd401b78da0f79650217625f36682ce87e91f09cd4489e2f9f4b45b36e83fb96d10d57d5f18c99f3171534a3bd4903faf3552aff6" ,
                                    text ? { }
                                } :
                                    let
                                        lambda =
                                            path : name : fun :
                                                let
                                                    text = fun injection ;
                                                    in
                                                        {
                                                            script = pkgs.writeShellScript name text ;
                                                            text = builtins.toFile name text ;
                                                        } ;
                                        mapper =
                                            path : name : value :
                                                if builtins.typeOf value == "lambda" then lambda value
                                                else if builtins.typeOf value == "path" then lambda ( builtins.import value )
                                                else if builtins.typeOf value == "set" then builtins.mapAttrs ( mapper ( builtins.concatLists [ path [ name ] ] ) ) value
                                                else invalid-text-value path name value ;
                                        in builtins.mapAttrs ( mapper [ ] ) text ;
                            observed =
                                derivation :
                                    let
                                        resource =
                                            lib
                                                {
                                                    injection =
                                                        {
                                                            networking.hostName = "dummy-host" ;
                                                            networking.networkmanager.enable = true ;
                                                            users.users.dummyUser =
                                                                {
                                                                    isNormalUser = true ;
                                                                    home = "/home/dummyUser" ;
                                                                    description = "A dummy user for testing purposes" ;
                                                                    extraGroups = [ "wheel" ] ;
                                                                    password = "dummyPassword123" ;
                                                                } ;
                                                            services.openssh.enable = true ;
                                                            services.nginx =
                                                                {
                                                                    enable = true ;
                                                                    virtualHosts =
                                                                        {
                                                                            "dummyHost.local" =
                                                                                {
                                                                                    root = "/var/www/dummy" ;
                                                                                    listen = [ { port = 80 ; address = "0.0.0.0" ; } ] ;
                                                                                    enableSSL = true;
                                                                                } ;
                                                                        } ;
                                                                } ;
                                                            environment.systemPackages =
                                                                with pkgs ;
                                                                [
                                                                    vim
                                                                    git
                                                                    cowsay
                                                                    jq
                                                                    curl
                                                                ] ;
                                                            time.timeZone = "America/New_York" ;
                                                            i18n.defaultLocale = "en_US.UTF-8";
                                                            services.httpd =
                                                                {
                                                                    enable = true ;
                                                                    adminAddr = "admin@dummyHost.local" ;
                                                                    documentRoot = "/var/www/dummy" ;
                                                                } ;
                                                            nix.gc.automatic = true ;
                                                            nix.gc.dates = "weekly" ;
                                                            nix.settings.max-jobs = "auto" ;
                                                        } ;
                                                    invalid-text-value = invalid-value "81695eef5ac6ba4c63febc98c21353fc6800119ff3153019188b649bef5b167b957eca223d030746302725efd8d59a45acb7de86423522d44703e9bd088fe0c3" ;
                                                    text =
                                                        {
                                                            document =
                                                                injection :
                                                                    ''
                                                                           # System Configuration Report

                                                                           ## Host Information:
                                                                           - Hostname: ${injection.networking.hostName}
                                                                           - Time Zone: ${injection.time.timeZone}
                                                                           - Locale: ${injection.i18n.defaultLocale}

                                                                           ## User Information:
                                                                           - Username: dummyUser
                                                                           - Home Directory: ${injection.users.users.dummyUser.home}
                                                                           - Description: ${injection.users.users.dummyUser.description}
                                                                           - Extra Groups: ${toString injection.users.users.dummyUser.extraGroups}

                                                                           ## Installed Packages:
                                                                           The following packages are installed on the system:

                                                                           ## Services:
                                                                           - SSH Enabled: ${if injection.services.openssh.enable then "Yes" else "No"}
                                                                           - Nginx Enabled: ${if injection.services.nginx.enable then "Yes" else "No"}
                                                                             - Virtual Host: ${builtins.attrNames injection.services.nginx.virtualHosts}

                                                                           ## Garbage Collection:
                                                                           - Automatic GC: ${if injection.nix.gc.automatic then "Enabled" else "Disabled"}
                                                                           - GC Schedule: ${injection.nix.gc.dates}

                                                                           This system was generated for testing purposes using NixOS.

                                                                           ## End of Report
                                                                    '' ;
                                                        } ;
                                                } ;
                                        in
                                    ''
                                        ${ pkgs.coreutils }/bin/cat ${ resource.document.script } > ${ environment-variable "OBSERVED" }/script &&
                                            ${ pkgs.coreutils }/bin/cat ${ resource.document.text } > ${ environment-variable "OBSERVED" }/text
                                    '' ;
                            pkgs = import nixpkgs { system = system ; } ;
                            in
                                {
                                    # checks.testLib = pkgs.runCommand "bash_unit" { buildInputs = [ ( bash_unit-checker { derivation = lib ; expected-path = ./expected ; observed = observed ; } ) ] ; } "bash_unit" ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}
