# FullMetalBody

[![Test](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml/badge.svg)](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml)

フルメタルボディは、before_actionの段階で入力値検証を行うためのRails Pluginです。

YAMLファイルにパラメーターのホワイトリストを記述し、許可されたキーと値の場合のみ、通過できます。

しかし、それ以外の場合、例えば制御文字入りの文字列やオーバーフロー狙いの大量の文字列などを検知した場合は即座に `400 Bad Request` を返します。

### ホワイトリストのフォーマット

フォーマットは、以下のようになります。

```yaml
---
controller_name:
  action_name:
    parameter_name:
      type: (string|number|date|boolean)
      options:
        validator_option1: (value)
        validator_option2: (value)
    array_parameters:
      type: array
      properties:
        parameter_name:
          type: (string|number|date|boolean)
          options:
            validator_option1: (value)
            validator_option2: (value)
```

### ホワイトリストのサンプル

例えば、以下のように `Article` モデルのScaffoldを作成したとします。

```bash
bin/rails g scaffold Article title:string content:text
```

それに対するホワイトリストは、以下のようになります。

```yaml
---
articles:
  index:
    p:
      type: number
  show:
    id:
      type: number
  create:
    article:
      title:
        type: string
      content:
        type: string
        options:
          max_length: 4096
  edit:
    id:
      type: number
  update:
    id:
      type: number
    article:
      title:
        type: string
      content:
        type: string
        options:
          max_length: 4096
  destroy:
    id:
      type: number
```

## 目次

* [FullMetalBody](#fullmetalbody)
  * [目次](#目次)
  * [インストール](#インストール)
  * [使い方](#使い方)
    * [マイグレーション](#マイグレーション)
    * [ApplicationControllerの修正](#ApplicationControllerの修正)
    * [ホワイトリストの雛形の作成](#ホワイトリストの雛形の作成)
    * [全てのパラメーターを許可したい場合](#全てのパラメーターを許可したい場合)
  * [開発に参加する](#開発に参加する)
    * [事前準備](#事前準備)
    * [テストを実行する](#テストを実行する)
  * [コントリビュート](#コントリビュート)
  * [ライセンス](#ライセンス)

## インストール

Gemfileに以下を追加してください。

```ruby
gem "full_metal_body"
```

そして、以下を実行してください。

```bash
$ bundle install
```

## 使い方

### マイグレーション

ホワイトリストに存在しないコントローラー、アクション、パラメーターキーをデータベースに保存するため、マイグレーションファイルを作ります。

```bash
bin/rails g full_metal_body:install
```

マイグレーションファイルができたら、以下を実行します。

```bash
bin/rails db:migrate
```

データベースに `blocked_actions` テーブルと、 `blocked_keys` テーブルが出来上がります。

### ApplicationControllerの修正

ApplicationControllerで `FullMetalBody::InputValidationAction` をincludeします。

```ruby
class ApplicationController < ActionController::Base
  include FullMetalBody::InputValidationAction
end
```

### ホワイトリストの雛形の作成

自分でホワイトリストを書いていくこともできますが、大変な作業となります。

そのため、フルメタルボディは、developmentモードの場合に各々のアクションにアクセスすることで、
`tmp/whitelist/**/*.yml` にホワイトリストの雛形を作成した上で例外を発生させます。
その際に、blocked_actionsテーブルとblocked_keysテーブルにもデータが登録されます。
また、ログにもその内容が出力されます。

例えば、 `GET article_path(@article)` にアクセスしたとすると、`tmp/whitelist/articles.yml` が作成されます。その内容は以下のようになります。

```yaml
---
articles:
  show:
    id:
      type: string
```

この内容を `config/whitelist/articles.yml` にコピーした後に再びアクセスすると、例外は起きなくなります。
この作業を各アクション毎に繰り返し行うことで、ホワイトリストを作っていきます。
デフォルトでは全て `string` として生成されますので、パラメーターに合った型(string|number|date|boolean)に変更してください。

雛形にはアクション毎にパラメーターが随時マージされていきますので、削除しなくても問題ありません。
例えば、この後に `DELETE article_path(@article)` にアクセスしたとすると、 `tmp/whitelist/articles.yml` は以下のようになります。

```yaml
---
articles:
  destroy:
    id:
      type: string
  show:
    id:
      type: string
```

### 全てのパラメーターを許可したい場合

GraphQLを使っている場合、 `variables` パラメーターに関してはクライアント側で定義するため、ホワイトリストを作成することができません。

そういう場合は、 `variables` 以下は全て許可する必要があります。全てを許可する場合、`_permit_all: true`を指定します。

```yaml
---
graphql:
  execute:
    operationName:
      type: string
    query:
      options:
        max_length: 1048576
      type: string
    variables:
      _permit_all: true
```

ただし、キーに関しては全て許可するものの、攻撃を防ぐため、値から型を推測し、その型のデフォルトのルールで入力値を検証します。

## 開発に参加する

リポジトリをcloneして開発を行ってください。

### 事前準備

開発するには、docker-composeでPostgreSQLを起動します。

```bash
docker-compose up -d
```

以下を実行します。

```bash
bundle install
```

### テストを実行する

テストはminitestを使っています。

```bash
bin/test
```

## コントリビュート

バグレポート、プルリクエストがありましたらよろしくお願いします。

## ライセンス

このgemはオープンソースで  [MIT License](https://opensource.org/licenses/MIT) でご利用いただけます。
