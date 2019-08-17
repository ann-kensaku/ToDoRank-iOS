//
//  ToDoListViewController.swift
//  ToDoRank-iOS
//
//  Created by yuki on 2019/08/17.
//  Copyright © 2019 yuki. All rights reserved.
//

import UIKit

class ToDoListViewController: UITableViewController {
    
    // アイテムの型、ToDo項目のtitleとチェック(done)の有無
    class Item {
        var title : String
        var done: Bool = false
        
        init(title: String) {
            self.title = title
        }
    }
    
    // この配列に作ったアイテムを追加していく
    var itemArray: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NaviBarのタイトルを大きく表示させる
        navigationController?.navigationBar.prefersLargeTitles = true
        // あらかじめ3つアイテムを作り、配列に追加
        itemArray += [Item(title: "Data1"),Item(title: "Data2"),Item(title: "Data3")]
    }
    
    // セルの数が指itemArray（の長さ）によって指定される
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    //それぞれのセルについてどーするか
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Main.storybordのToDoItemCellがここのcell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoCell", for: indexPath)
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        //doneがtrueならチェックマーク、falseならなし
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    // 選択されたセルに実行される処理
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemArray[indexPath.row]
        // チェックマーク
        item.done = !item.done
        // リロードして変えた部分だけに反映
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        // セルを選択した時の背景の変化を遅くする、かっこいい
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // アイテム削除処理
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        itemArray.remove(at: indexPath.row)
        let indexPaths = [indexPath]
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }
    
    // 項目追加ボタンが押された時に実行される処理
    //これがstoryboardの+と紐付けされている
    @IBAction func addButtonPressed(_ sender: Any) {
        //追加するアイテムの名前入れる
        var textField = UITextField()
        //popup、かっこいい
        let alert = UIAlertController(title: "新しいアイテムを追加", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "リストに追加", style: .default) { (action) in
            // 追加されるアイテム
            let newItem: Item = Item(title: textField.text!)
            // アイテム追加処理
            self.itemArray.append(newItem)
            self.tableView.insertRows(at: [IndexPath(row: self.itemArray.count-1 , section: 0)], with: .automatic)
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "新しいアイテム"
            //text内容じゃなくてそのものが同一だからセーフ
            textField = alertTextField
        }
        
        alert.addAction(action)
        //かっこいい
        present(alert, animated: true, completion: nil)
    }
}


