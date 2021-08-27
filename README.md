## Terraform versions ~>v0.14.0 vs ~>v0.15.0 vs ~>v1.0.0

When upgrading between major releases of Terraform it's recommended to go through the list of changes which are usually available in the `Terraform Changelog`. And while doing upgrades if you run into any problems that are not addressed by the information in the given guide, they ask you to start a topic in [The Terraform community forum](https://discuss.hashicorp.com/c/terraform-core/27). 

### Terraform version 0.14.0

Previously in Terraform `v0.13` and earlier, the `terraform init` command would always install the newest version of any provider in the configuration that would meet the configured version constraints. But starting from v.014 `terraform init` will also generate a `lock file` in the configuration directory which you can check in to your version control so that Terraform can make the same version selections in future. Here some changes that were introduced in `v0.14`:

- Terraform `v0.14` started  to generate an explicit `deprecation warning`.
- The `terraform 0.13upgrade` subcommand and the associated upgrade mechanisms are no longer available. 
- The `debug` command, which did not offer additional functionality, has been removed.

### Terraform version 0.15.0

Terraform `v0.15` is a major release and so it includes some small changes in behavior that you may need to consider when upgrading. Unlike the previous few Terraform major releases, v0.15's upgrade concerns are largely conclusions of deprecation cycles left over from previous releases, many of which already had deprecation warnings in `v0.14`.

#### Upgrade guide sections:

- Sensitive Output Values
Terraform v0.14 previously introduced the ability for Terraform to track and propagate the "sensitivity" of values through expressions that include references to sensitive input variables and output values.
```
resource "aws_db_instance" "rds-db" {
  allocated_storage    = var.storage
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = var.instance_class
  identifier           = "${var.env}-rds"
  name                 = "my-rdsdb"
  username             = var.username
  password             = random_password.password.result
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%"
}

variable "db_password" {
  type        = string
  description = "this is rds user db password"
  sensitive   = true
}

output "password" {
    value = aws_db_instance.rds-db.password
    description = "this is the  address of rds instance"
    sensitive = true 
}
```
If you consider Terraform's treatment of a sensitive value to be too conservative and you'd like to force Terraform to treat a sensitive value as non-sensitive, you can use the nonsensitive function to override Terraform's automatic detection:

```
output "private_key" {
  # WARNING: Terraform will display this result as cleartext
  value = nonsensitive(tls_private_key.example.private_key_pem)
}
```

#### Legacy Configuration Language Features

- The `built-in functions` such as `list` and `map` were replaced with first-class syntax [ ... ] and { ... } in Terraform v0.12, and but now it was removed the deprecated functions in order to resolve the ambiguity with the syntax used to declare list and map type constraints inside variable blocks. If you need to update a module which was using the list function, you can get the same result by replacing list(...) with tolist([...]). For example:

```
- list("a", "b", "c")
+ tolist(["a", "b", "c"])
```
If you need to update a module which was using the map function, you can get the same result by replacing map(...) with tomap({...}). For example:
```
- map("a", 1, "b", 2)
+ tomap({ a = 1, b = 2 })
```
However, in most situations those explicit type conversions won't be necessary because Terraform can infer the necessary type conversions automatically from context. In those cases, you can just use the [ ... ] or { ... } syntax directly, without a conversion function.

- In `variable` declaration blocks, the type argument previously accepted v0.11-style type constraints given as quoted strings. This legacy syntax is removed in Terraform v0.15. To update an old-style type constraint to the modern syntax, start by removing the quotes so that the argument is a bare keyword rather than a string:

```
variable "example" {
  type = "string"
}

variable "example" {
  type = string
}
```

Additionally, if the previous type constraint was either `"list"` or `"map"`, add a type argument to specify the element type of the collection. Terraform v0.11 typically supported only collections of strings, so in most cases you can set the element type to string:

```
variable "example" {
  type = list(string)
}

variable "example" {
  type = map(string)
}
```

- In `lifecycle` blocks nested inside `resource` blocks, Terraform previously supported a legacy value ["*"] for the `ignore_changes` argument, which is removed in Terraform v0.15.
Instead, use the all keyword to indicate that you wish to ignore changes to all of the resource arguments:

```
  lifecycle {
    ignore_changes = all
  }
```

Terraform `v0.11` and earlier required all non-constant expressions to be written using string interpolation syntax, even if the result was not a string. Terraform `v0.12` introduced a less confusing syntax where arguments can accept any sort of expression without any special wrapping, and so the interpolation-style syntax has been redundant and deprecated.

For this particular change we have not made the older syntax invalid, but we do still recommend updating interpolation-only expressions to bare expressions to improve readability:

```
  - example = "${var.foo}"
  + example = var.foo
```
This only applies to arguments where the value is a single expression without any string concatenation. You must continue to use the ${ ... } syntax for situations where you are combining string values together into a larger string.

The `terraform fmt` command can detect and repair simple examples of the legacy interpolation-only syntax, and so it's recommended running `terraform fmt` on your modules once you've addressed any of the other situations above that could block configuration parsing in order to update your configurations to the typical Terraform language style conventions.

#### Alternative Provider Configurations Within Modules

The required_providers block now has a new field for providers to indicate aliased configuration names, replacing the need for an empty "proxy configuration block" as a placeholder. In order to declare configuration aliases, add the desired names to the `configuration_aliases` argument for the provider requirements.

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      configuration_aliases = [ aws.alternate ]
    }
  }
}
```
Warnings will be emitted now where empty configuration blocks are present but no longer required, though they continue to work unchanged in the 0.15 release. There are a few cases where existing configurations may return new errors:

- The `providers` map in a module call cannot override a provider configured within the module. This is not a supported configuration, but was previously missed in validation and now returns an error.

- A provider alias within a module that has no configuration requires a provider configuration be supplied in the module `providers` map.

- All entries in the `providers` map in a module call must correspond to a provider name within the module. Passing in a configuration to an undeclared provider is now an error.

#### Commands Accepting a Configuration Directory Argument

A subset of Terraform's CLI commands have historically accepted a final positional argument to specify which directory contains the root module of the configuration, overriding the default behavior of expecting to find it in the current working directory. However, the design of that argument was flawed in a number of ways due to it being handled at the wrong level of abstraction: it only changed where Terraform looks for configuration and not any of the other files that Terraform might search for, and that could therefore violate assumptions that Terraform configurations might make about the locations of different files, leading to confusing error messages. It was also not possible to support this usage pattern across all commands due to those commands using positional arguments in other ways.

To address these design flaws, Terraform `v0.14` introduced a new global option `-chdir` which you can use before the subcommand name, causing Terraform to run the subcommand as if the given directory had been the current working directory:

```
$ terraform -chdir=example init
```
This command causes the Terraform process to actually change it's current working directory to the given directory before launching the subcommand, and so now any relative paths accessed by the subcommand will be treated as relative to that directory, including (but not limited to) the following key directory conventions:

- As with the positional arguments that `-chdir` replaces, Terraform will look for the root module's `.tf` and `.tf.json` files in the given directory.

- The `.tfvars` and `.tfvars.json` files that Terraform automatically searches for, and any relative paths given in `-var-file` options, will be searched in the given directory.

- The `.terraform` directory which Terraform creates to retain the working directory internal state will appear in the given directory, rather than the current working directory.

After treating the `v0.14` releases as a migration period for this new behavior, Terraform CLI `v0.15` no longer accepts configuration directories on any command except `terraform fmt`. (terraform fmt is special compared to the others because it primarily deals with configuration files in isolation, rather than modules or configurations as a whole.)
If you built automation which previously relied on overriding the configuration directory alone, you will need to transition to using the `-chdir` command line option before upgrading to Terraform `v0.15`.

Since the `-chdir` argument behavior is more comprehensive than the positional arguments it has replaced, you may need to make some further changes in the event that your automation was relying on the limitations of the old mechanism:

- If your system depends on the `.terraform` directory being created in the real current working directory while using a root module defined elsewhere, you can use the `TF_DATA_DIR` environment variable to specify the absolute path where Terraform should store its working directory internal state:
```
TF_DATA_DIR="$PWD/.terraform"
```

- If your system uses `.tfvars` or `.tfvars.json` files either implicitly found or explicitly selected in the current working directory, you must either move those variables files into the root module directory or specify your files from elsewhere explicitly using the `-var-file` command line option:
```
terraform plan -var-file="$PWD/example.tfvars"
```
As a special case for backward compatibility, Terraform ensures that the language expression path.cwd will return the original working directory, before overriding with `-chdir`, so that existing configurations referring to files in that directory can still work. If you want to refer to files in the directory given in `-chdir` then you can use `path.root`, which returns the directory containing the configuration's root module.

#### Microsoft Windows Terminal Support

Until the first `Windows 10` update, Microsoft Windows had a console window implementation with an API incompatible with the virtual terminal approach taken on all other platforms that Terraform supports.

Previous versions of Terraform accommodated this by using an API translation layer which could convert a subset of typical virtual terminal sequences into corresponding Windows Console API function calls, but as a result this has prevented Terraform from using more complex terminal features such as progress indicators that update in place, menu prompts, etc.

Over the course of several updates to `Windows 10`, Microsoft has introduced virtual terminal support similar to other platforms and now recommends the virtual terminal approach for console application developers. In response to that recommendation, Terraform `v0.15`` no longer includes the terminal API translation layer and consequently it will, by default, produce incorrectly-formatted output on Windows 8 and earlier, and on non-updated original retail Windows 10 systems.

If you need to keep using Terraform on an older version of Windows, there are two possible workarounds available in the `v0.15.0` release:

- Run Terraform commands using the -no-color command line option to disable the terminal formatting sequences.

- This will cause the output to be unformatted plain text, but as a result will avoid the output being interspersed with uninterpreted terminal control sequences.

- Alternatively, you can use Terraform v0.15.0 in various third-party virtual terminal implementations for older Windows versions, including ConEmu, Cmder, and mintty.

Although terraform have no immediate plans to actively block running Terraform on older versions of Windows, they will not be able to test future versions of Terraform on those older versions and so later releases may contain unintended regressions. They recommend planning an upgrade to a modern Windows release on any system where you expect to continue using Terraform CLI.

#### Other Minor Command Line Behavior Changes

Finally, Terraform `v0.15` includes a small number of minor changes to the details of some commands and command line arguments, as part of a general cleanup of obsolete features and improved consistency:

- Interrupting Terraform commands with your operating system's interrupt signal (SIGINT on Unix systems) will now cause Terraform to exit with a non-successful exit code. Previously it would, in some cases, exit with a success code.

This signal is typically sent to Terraform when you press `Ctrl+C` or similar interrupt keyboard shortcuts in an interactive terminal, but might also be used by automation in order to `gracefully cancel` a long-running Terraform operation.

- The `-lock` and `-lock-timeout` options are no longer available for the terraform init command. Locking applies to operations that can potentially change remote objects, to help ensure that two concurrent Terraform processes don't try to run conflicting operations, but `terraform init` does not interact with any providers in order to possibly effect such changes.

These options didn't do anything in the `terraform init` command before, and so you can remove them from any automated calls with no change in behavior.

- The `-verify-plugins` and `-get-plugins` options to `terraform init` are no longer available. These have been `non-functional` since Terraform `v0.13`, with the introduction of the new Terraform Registry-based provider installer, because in practice there are very few operations Terraform can perform which both require a terraform init but can also run without valid provider plugins installed.

If you were using these options in automated calls to `terraform init`, remove them from the command line for compatibility with Terraform `v0.15`. There is no longer an option to initialize without installing the required provider plugins.

- The `terraform destroy` command no longer accepts the option `-force`. This was a previous name for the option in earlier Terraform versions, but since they have adopted `-auto-approve` for consistency with the terraform apply command. If you are using `-force` in an automated call to terraform destroy, change to using `-auto-approve` instead.

#### Azure Backend Removed Arguments

In an earlier release the `azure backend` changed to remove the `arm_` prefix from a number of the configuration arguments:

 Old Name| New Name | 
--- | --- | 
arm_client_id | client_id | 
arm_client_secret | client_secret |
arm_subscription_id | subscription_id |
arm_tenant_id  | tenant_id |

The old names were previously deprecated, but now they were removed altogether in Terraform `v0.15` in order to conclude that deprecation cycle.

If you have a backend configuration using the old names then you may see errors like the following when upgrading to Terraform v0.15:

```
Error: Invalid backend configuration argument

The backend configuration argument "arm_client_id" given on
the command line is not expected for the selected backend type.
```

If you see errors like this, rename the arguments in your backend configuration as shown in the table above and then run the following to `re-initialize` your backend configuration:

```
terraform init -reconfigure
```

The `-reconfigure` argument instructs Terraform to just replace the old configuration with the new configuration directly, rather than offering to migrate the latest state snapshots from the old to the new configuration. Migration would not be appropriate in this case because the old and new configurations are equivalent and refer to the same remote objects.

### Terraform version 1.0.0

Terraform `v1.0.0` is an unusual release in that its primary focus is on stability, and it represents the culmination of several years of work in previous major releases to make sure that the Terraform language and internal architecture will be a suitable foundation for forthcoming additions that will remain backward-compatible.

Terraform `v1.0.0` intentionally has no significant changes compared to Terraform `v0.15.5`. You can consider the `v1.0` series as a direct continuation of the `v0.15` series.

I updated Terraform `v0.14.0` to `v1.0.0` and before doing anything it's recommended to see the list of changes that were made in `v0.15.0` which are in the notes from the `Terraform v0.15 upgrade guide`. Since I have multiple separate Terraform configurations that collaborate together using the `terraform_remote_state` data source, I didn't really face any huge differences between those versions because all three versions have intercompatible state snapshot formats.

But if you are currently using Terraform `v0.13` or earlier then they strongly recommend upgrading one major version at a time until you reach Terraform v0.14, following the upgrade guides of each of those versions, because those earlier versions include mechanisms to automatically detect necessary changes to your configuration, and in some cases also automatically edit your configuration to include those changes. One you reach Terraform `v0.14` you can then skip directly from there to Terraform `v1.0.0`.

### How to update terraform v0.14.0 to v1.0.0?

To start with you need to remove the old version of terraform, after that run the following script.
```
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y wget 
  sudo yum install -y unzip
  wget  https://releases.hashicorp.com/terraform/1.0.0/terraform_1.0.0_linux_amd64.zip
  unzip terraform_1.0.0_linux_amd64.zip
  sudo mv terraform /usr/bin/
```

### Helpful resources:

1. [Upgrading to Terraform v0.14](https://www.terraform.io/upgrade-guides/0-14.html)
2. [Upgrading to Terraform v0.15](https://www.terraform.io/upgrade-guides/0-15.html)
3. [Upgrading to Terraform v1.0](https://www.terraform.io/upgrade-guides/1-0.html)
4. [Download Terraform](https://www.terraform.io/downloads.html)