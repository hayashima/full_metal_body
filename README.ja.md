# FullMetalBody

[![Test](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml/badge.svg)](https://github.com/hayashima/full_metal_body/actions/workflows/test.yml)

フルメタルボディは、`before_action`の段階でリクエストパラメーターの値を検証するRailsプラグインです。

YAMLファイルにパラメーターのホワイトリストを記述すると、記載されたパラメーターの値を検証します。

しかし、それ以外の場合、例えば制御文字入りの文字列やオーバーフロー狙いの大量の文字列などを検知した場合は即座に `400 Bad Request` を返します。

### ホワイトリストのフォーマット

フォーマットは、以下のようになります。

```yaml
---
controller_name:
  action_name:
    parameter_name:
      type: (string|number|date|boolean|file)
      options:
        validator_option1: (value)
        validator_option2: (value)
    array_parameters:
      type: array
      properties:
        parameter_name:
          type: (string|number|date|boolean|file)
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
    * [入力値の検証オプション](#入力値の検証オプション)
    * [ホワイトリストの雛形の作成](#ホワイトリストの雛形の作成)
    * [全てのパラメーターを許可したい場合](#全てのパラメーターを許可したい場合)
    * [不明なパラメーター数チェックを無効にする](#不明なパラメーター数チェックを無効にする)
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

### 入力値の検証オプション

FullMetalBodyは値を検証しますが、RailsのStrong Parametersの代わりにはなりません。`params`からキーを削除しないため、一括代入に渡す属性は`permit`で制御してください。また、値の型は変換しません。例えば、`"123"`は`number`の検証に通っても文字列のままです。

リクエストに含まれる値だけを検証します。必須項目や、値が配列・ハッシュであることはアプリケーション側で検証してください。型ごとのオプションは`options`に指定します。

| 型 | オプションとデフォルト |
| --- | --- |
| `string` | `max_length`のデフォルトは`1024`文字です。`pattern`は値全体に一致させます。 |
| `number` | Active Modelの数値検証オプションを指定できます。オプションを省略すると空値を許可します。 |
| `date` | `format`を省略すると、`YYYY/M/D`または`YYYY-M-D`形式の有効な日付を受け付けます。`minimum`と`maximum`は両端を含みます。 |
| `boolean` | `true_values`と`false_values`は文字列配列で指定します。空値を許可するには`allow_blank: true`を指定します。 |
| `file` | `content_type`は文字列または配列で、デフォルトは`*`です。`file_size`はデフォルトで100 MiBです。`allowed_extensions`でファイル名のサフィックスを制限します。 |

追加の注意点:

- `string`は有効なUTF-8である必要があります。改行と水平タブ以外の制御文字は拒否します。`pattern`には`/.../`ではなくRuby正規表現を文字列で指定してください。
- `date`の`format`には`'%Y-%m-%d'`のようなRubyの`Date`形式を指定します。`minimum`と`maximum`は引用符で囲んだISO 8601形式にしてください。
- `boolean`はデフォルトで`true`、`false`および`"1"`、`"t"`、`"T"`、`"true"`、`"TRUE"`、`"on"`、`"ON"`、`"0"`、`"f"`、`"F"`、`"false"`、`"FALSE"`、`"off"`、`"OFF"`を受け付けます。独自値を設定してもBooleanの`true`と`false`は受け付けます。
- `file`の`content_type`は申告された値を確認し、ファイルの実データは確認しません。`allowed_extensions`は大文字小文字を区別せず、`.tar.gz`のような複合サフィックスにも対応します。空配列は全ファイルを拒否し、`nil`は拡張子を制限しません。
- `number`、`date`、`boolean`に文字列を渡すと、デフォルトの`string`ルールでも検証します。

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
デフォルトでは全て `string` として生成されますので、パラメーターに合った型(string|number|date|boolean|file)に変更してください。

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
配列要素の型を含め、既存の定義があれば型とオプションを保持します。要素の型が未定義の配列では、各要素の値から個別に型を推測します。

### 不明なパラメーター数チェックを無効にする

FullMetalBodyはデフォルトで3つまで、不明なパラメーターを許可しています。
これは、ホワイトリストが全て揃った後でも、想定外のパラメーターが残っていた場合にエラーを起こさないために余裕を持たせているのですが、
ホワイトリストを作っている最中の場合は3つ以上のパラメーターを検知してすぐにエラーになってしまいます。

そのため、ホワイトリストを作っている最中は、無効にしておくことをお薦めします。
無効にするには、環境変数 `ENV['USE_WHITELIST_COUNT_CHECK']` に `0` を設定します。

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
