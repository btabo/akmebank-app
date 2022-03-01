# Demo for Akme Bank with COS    
 
App based on [Command Query Responsibility Segregation (CQRS)](https://martinfowler.com/bliki/CQRS.html)
Using Java and Quarkus and COS Java SDK. 
 
## Deploying
  
  
Deploying the account-command-ms: 

```bash 
cd account-command-ms 
make deploy 
```

Deploying the account-query-ms:

```bash
cd account-query-ms
make deploy
```

## Loading customer data in COS

This is list of available commands:

```bash
accounts <command>

Commands:
  accounts create <n>                   create n users with 3 accounts each
  accounts create-named <first> <last>  create named user with 3 accounts
  accounts delete-users                 delete all users
  accounts delete-accounts              delete all accounts
  accounts list-users                   list all users
  accounts list-accounts                list all accounts
```
 
To create 10 random users with accounts, run:

```bash
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- create 10
```

For the demo, create a named user with accounts as follow:

```bash
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- create-named Jack Doe
```

To list users, run:

```bash
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- list-users
```

To list accounts, run:

```bash
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- list-accounts
```

To delete all users and accounts, run:

```bash
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- delete-accounts
kubectl run cli --rm -it --image us.icr.io/paolo/account-cli --restart=Never --quiet=true -- delete-users
```

AKME Terraform configuration for Cloud infrastructure. 

![AKME Architecture](https://github.ibm.com/think2020/terraform-ca/blob/master/AKME_arch1.png)
