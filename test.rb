require 'selenium-webdriver' # seleniumを使用するためのGem
require 'date'

# chrome用のドライバを生成
driver = Selenium::WebDriver.for :chrome
# 特定の要素が表示されるまでの待ち時間を設定
wait = Selenium::WebDriver::Wait.new(timeout: 5)

# Salesforceにアクセス
driver.navigate.to "https://innovation.my.salesforce.com/home/home.jsp"

# ユーザー名を入力
wait.until { driver.find_element(:id, 'username').displayed? }
driver.find_element(:id, 'username').send_keys ENV['SALESFORCE_MAIL']

# パスワードを入力
wait.until { driver.find_element(:id, 'password').displayed? }
driver.find_element(:id, 'password').send_keys ENV['SALESFORCE_PASS']

# ログインボタンをクリック
driver.find_element(:id, 'Login').click

sleep(3)

# ホームが表示されない場合
if driver.title != "Salesforce - Enterprise Edition"
    # 新しいウィンドウを開く
    driver.execute_script("window.open()")

    # driverを新しいウィンドウに向ける
    new_window = driver.window_handles.last
    driver.switch_to.window(new_window)

    # Gmailを開く
    driver.navigate.to "https://gmail.com/"

    # メールアドレスの入力
    wait.until { driver.find_element(:id, 'identifierId').displayed? }
    driver.find_element(:id, 'identifierId').send_keys ENV['GMAIL_MAIL']
    driver.find_element(:id, 'identifierNext').click

    #パスワードの入力
    wait.until { driver.find_element(:xpath, '//input[@type="password"]').displayed? }
    driver.find_element(:xpath, '//input[@type="password"]').send_keys ENV['GMAIL_PASS']
    driver.find_element(:id, 'passwordNext').click

    # Gmailが開かれるのを待つ
    sleep(7)

    # Salesforceから送られてくるID確認のメールから認証コードを取得する
    identification_code = 0
    driver.find_element(:xpath, '//tbody').find_elements(:xpath, '//tr').each { |element|
        # 該当のメールを件名から判定
        if element.text.include?("Salesforce で ID を確認") then
            # 該当のメールを開く
            element.click
            # 認証コードを取得
            wait.until { driver.find_element(:class, 'adn').displayed? }
            identification_code = driver.find_element(:class, 'adn').text[/確認コード: (\d*).*/, 1]
            break
        end
    }

    # エラー処理
    if identification_code == 0 then
        puts('認証コードを取得できませんでした')
        exit
    end

    # driverをSalesforceウィンドウに向ける
    new_window = driver.window_handles.first
    driver.switch_to.window(new_window)

    # 認証コードを入力
    wait.until { driver.find_element(:id, 'emc').displayed? }
    driver.find_element(:id, 'emc').send_keys identification_code

    # 検証ボタンをクリック
    driver.find_element(:id, 'save').click
end

# 勤務表をクリック
wait.until { driver.find_element(:id, '01r10000000DwLW_Tab').displayed? }
driver.find_element(:id, '01r10000000DwLW_Tab').click

# 今日の日付をフォーマットして取得
today = Date.today.strftime("%Y-%m-%d")

# 今日の工数入力ボタンをクリック
wait.until { driver.find_element(:id, 'dailyWorkCell' + today).displayed? }
driver.find_element(:id, 'dailyWorkCell' + today).click

# 作業報告を入力
wait.until { driver.find_element(:id, 'empWorkTableNote').displayed? }
driver.find_element(:id, 'empWorkTableNote').clear
driver.find_element(:id, 'empWorkTableNote').send_keys "テスト"

# 各タスクに作業時間を入力
driver.find_element(:id, 'empWorkTableBody').find_elements(:xpath, '//tbody[@id="empWorkTableBody"]/tr').each_with_index { |row, index|
    # clearとsend_keysを使用して値を書き換えようとすると、clearをした段階でSalesforce側で「0:00」の値を入れる処理が動作して結果的に値を削除できないので、JavaScriptを実行して値を書き換える
    driver.execute_script("document.getElementById('empInputTime" + index.to_s + "').value = '00:10'")
}

# 登録ボタンをクリック
driver.find_element(:id, 'empWorkOk').click

sleep(3)

# テストを終了する（ブラウザを終了させる）
driver.quit

# 今月の全ての工数を入力するメソッド
# 使うかも知れないので書いておく
def monthlyMonHourInput
    driver.find_element(:id, 'mainTableBody').find_elements(:tag_name, 'tr').each { |row|
        # 土日・祝日の場合はスキップ
        if row.attribute('class').include?('rowcl1') || row.attribute('class').include?('rowcl2') then
            next
        end

        # 工数入力
    }
end
