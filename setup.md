# Getting Started

## 事前準備

- AWSアカウントの作成
  - [AWS アカウント作成の流れ](https://aws.amazon.com/jp/register-flow/)
    - クレジットカード情報が必要
- sshキーの発行とGitHubへの登録
  - [新しい SSH キーを生成して ssh-agent に追加する](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
  - [GitHub アカウントへの新しい SSH キーの追加](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

## Installation Guide

[!WARNING]
Critical content demanding immediate user attention due to potential risks.

### AWSで利用するためのテンプレートファイルを作成する

ISUCON用のサイトをCloudFormationを利用して構築する。  
その際に利用するテンプレートファイルを完成させる。[^1]

1. エディタを開き任意名の`.yaml`ファイルを作成。  
2. 利用するGitHubアカウントのユーザー名を`<YOUR_ACCOUNT_NAME>`とし、[現在のグローバルIPアドレスを確認](https://www.cman.jp/network/support/go_access.cgi)し`<YOUR_GLOBAL_IP_ADDRESS>`に置き換える。  

[^1]: 社内LANを利用している場合は正しく稼働しない  
 なので`0.0.0.0/0`とやると手っ取り早いが...  
 IPアドレス情報は[COCOらぼ](https://faq-oh.r.recruit.co.jp/usr/file/attachment/3ag23e3K4sO0DO8W.txt?attachment_log=1&object_id=9443&object_type=faq&site_domain=JP)に記載あり

```yaml
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.1.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: project
          Value: private-isu
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: project
          Value: private-isu
  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway
  PublicSubnet1a:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.1.1.0/24
      AvailabilityZone: ap-northeast-1a
      Tags:
        - Key: project
          Value: private-isu
  PublicSubnetRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
  PublicSubnetRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicSubnetRouteTable
      SubnetId: !Ref PublicSubnet1a
  PublicRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PublicSubnetRouteTable
      GatewayId: !Ref InternetGateway
      DestinationCidrBlock: 0.0.0.0/0

  PrivateSubnet1a:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.1.100.0/24
      AvailabilityZone: ap-northeast-1a
      Tags:
        - Key: project
          Value: private-isu
  IsuconInstance:
    Type: AWS::EC2::Instance
    Properties:
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: '1'
      Monitoring: false
      NetworkInterfaces:
        - AssociatePublicIpAddress: true
          DeviceIndex: '0'
          SubnetId: !Ref PublicSubnet1a
          GroupSet:
            - !Ref AllowSSHAndHTTPSG
      UserData: !Base64
        Fn::Sub: |
          #!/bin/bash -xe
          curl https://github.com/<YOUR_ACCOUNT_NAME>.keys >> /home/ubuntu/.ssh/authorized_keys
  AllowSSHAndHTTPSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: PublicSG
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: <YOUR_GLOBAL_IP_ADDRESS>/32
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: <YOUR_GLOBAL_IP_ADDRESS>/32
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 18.179.155.67/32
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        ImageId: ami-0bed62bba4100a4b7
        InstanceMarketOptions:
          MarketType: spot
        InstanceType: c7g.large
```

### AWSにログインし先ほどのyamlファイルをアップロード

1. AWSにログインしコンソールにアクセスする
2. Regionを東京にする
3. CloudFormationを開く
4. `スタックの作成` > `新しいリソースを使用(標準)`を選択
5. `前提条件 - テンプレートの準備` > `既存のテンプレートを選択`
6. `テンプレートの指定` > `テンプレートファイルのアップロード` より`ファイルの選択`から先ほどのファイルをアップロード
7. あとは全て`次へ`を押して送信
8. 1分ほど待ちステータスが`CREATE_COMPLETE`になれば完了！

### Webサイトが閲覧できるか確認する

1. EC2にアクセスする
2. `パブリック IPv4 アドレス`と`パブリック IPv4 DNS`をメモする
3. `http://<パブリック IPv4 DNS>`にアクセスしIscogramが表示されていることを確認する[^2]

[^2]: `http://`になっているか確認する  
 AWSコンソールの`オープンアドレス`を押してアクセスした場合は`https://`になっている  
 それでも解決しない場合はセキュリティグループを確認し`ssh`と`http`で`0.0.0.0/0`を採用するか検討する

### ssh接続ができることを確認する

ssh接続ができることを確認する。[^3]

```shell
ssh -i <秘密鍵のパス> ubuntu@<パブリック IPv4 アドレス>
# 入力例 
ssh -i ~/.ssh/id_ed25519 ubuntu@43.207.157.244
```

[^3]: 実際に検証したところ`ssh`で入ることができなかった  
  `ssh`のインバウンドルールを`0.0.0.0/0`にしたら解決したが本質的な修正ではなさそう
