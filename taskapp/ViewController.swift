//
//  ViewController.swift
//  taskapp
//
//  Created by 0001 QBS on 2020/05/01.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import RealmSwift
import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    @IBOutlet var tableView: UITableView!
    
    private var searchController: UISearchController!
    
    private var filteredTitles = [String]()
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    // カテゴリでフィルタした結果が格納されるリスト。
    var filterTasks = try! Realm().objects(Task.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // UISearchControllerのインスタンスを生成
        searchController = UISearchController(searchResultsController: nil)
        // 結果表示用のビューコントローラーにViewControllerを設定
        searchController.searchResultsUpdater = self
        // 検索結果を自動で表示しない
        searchController.obscuresBackgroundDuringPresentation = false
        // 画面遷移時に検索バーを非表示
        definesPresentationContext = true
        // テーブルビューのヘッダーに検索バーを設定
        tableView.tableHeaderView = searchController.searchBar
        
        navigationItem.title = "タスク管理アプリ"
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // 検索ワードを格納
        let searchText = searchController.searchBar.text!
        
        // キーワード一致した結果のみリストに格納
        filterTasks = taskArray.filter("category LIKE %@", "*" + searchText + "*")
        
        // テーブルビューを再読み込みする。
        tableView.reloadData()
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 検索している場合
        if searchController.searchBar.text != "" {
            return filterTasks.count
            // 検索していない場合
        } else {
            return taskArray.count // ←修正する
        }
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // 取得したタスクを格納する変数
        var task: Task!
        
        // Tag番号でセルに含まれるラベルを取得する。
        let label1 = cell.viewWithTag(1) as! UILabel
        let label2 = cell.viewWithTag(2) as! UILabel
        let label3 = cell.viewWithTag(3) as! UILabel
        
        // 検索している場合
        if searchController.searchBar.text != "" {
            task = filterTasks[indexPath.row]
            // 検索していない場合
        } else {
            task = taskArray[indexPath.row]
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString: String = formatter.string(from: task.date)
        
        // それぞれのラベルに値を設定
        label1.text = "カテゴリ : " + task.category
        label2.text = "タイトル : " + task.title
        label3.text = "日時　　 : " + dateString
        
        return cell
    }
    
    // セルの高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}
