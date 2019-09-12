//
//  ToDoListViewController.swift
//  ToDoRank-iOS
//
//  Created by yuki on 2019/08/17.
//  Copyright © 2019 yuki. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class ToDoListViewController: UITableViewController {
    //Realmをインスタンス化
    let realm = try! Realm()
    // この配列に作ったアイテムを追加していく
    var itemArray: Results<Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemArray = realm.objects(Item.self)
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
        try! self.realm.write {
            // チェックマーク
            itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        }
        // リロードして変えた部分だけに反映
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        // セルを選択した時の背景の変化を遅くする、かっこいい
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //横スワイプの処理(edit,delete)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit_action = UITableViewRowAction(style: .default, title: "edit"){ (action, indexPath) in
            //名前を編集
            //新しいアイテムの名前入れる
            var textField = UITextField()
            //popup、かっこいい
            let alert = UIAlertController(title: "編集", message: "", preferredStyle: .alert)
            
            let add_action = UIAlertAction(title: "完了", style: .default) { (action) in
                // 変更される名前が入力されていれば
                if (textField.text ?? "").count > 0{
                    try! self.realm.write {
                        self.itemArray[indexPath.row].title = textField.text!
                    }
                    // リロードしてUIに反映
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                } else {//入力されなきゃ何もしない
                }
            }
            
            alert.addTextField { (alertTextField) in
                //元の名前が入ってる
                alertTextField.placeholder = self.itemArray[indexPath.row].title
                //text内容じゃなくてそのものが同一だからセーフ
                textField = alertTextField
                
            }
            alert.addAction(add_action)
            //かっこいい
            self.present(alert, animated: true, completion: nil)
            
        }
        edit_action.backgroundColor = UIColor.lightGray
        
        let delete_action = UITableViewRowAction(style: .default, title: "Delete"){ (action, indexPath) in
            //データベース上の削除
            try! self.realm.write {
                self.realm.delete(self.itemArray[indexPath.row])
            }
            //表示上のアイテム削除処理
            let indexPaths = [indexPath]
            tableView.deleteRows(at: indexPaths, with: .automatic)
            //表示は平気だけど削除でrealmの中がごちゃってるからソートしよう
            self.itemArray = self.itemArray.sorted(byKeyPath: "rank", ascending: true)
        }
        
        return [delete_action,edit_action]
    }
    
    // 項目追加ボタンが押された時に実行される処理
    //これがstoryboardの+と紐付けされている
    @IBAction func addButtonPressed(_ sender: Any) {
        //追加するアイテムの名前入れる
        var nameTextField = UITextField()
        var rankTextField = UITextField()
        //popup、かっこいい
        let alert = UIAlertController(title: "新しいアイテムを追加", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "リストに追加", style: .default) { (action) in
            // 追加されるアイテム
            let newItem = Item()
            //追加アイテムを聞かれた時に文字を入れた場合だけ処理(rankは今後の実装で変わる処理なので、暫定的に常に良い感じに入力されてると仮定しエラーは考えない)
            if (nameTextField.text ?? "").count > 0{
                newItem.title = nameTextField.text!
                newItem.rank = Int(rankTextField.text!)!
                try! self.realm.write{
                    // アイテム追加処理
                    self.realm.add(newItem)
                    //realmの中がごちゃってるからソートしよう
                    self.itemArray = self.itemArray.sorted(byKeyPath: "rank", ascending: true)
                }
                //sortされたitemArrayから今回のrankの場所を得る（若干2度手間感あるが）
                let searchedPath = self.binarySearch(rank: newItem.rank)!
                self.tableView.insertRows(at: [IndexPath(row: searchedPath , section: 0)], with: .automatic)
            } else {//入力されなきゃ何もしない
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "新しいアイテム"
            //text内容じゃなくてそのものが同一だからセーフ
            nameTextField = alertTextField
        }
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "ランク"
            //text内容じゃなくてそのものが同一だからセーフ
            rankTextField = alertTextField
        }
        alert.addAction(action)
        //かっこいい
        present(alert, animated: true, completion: nil)
    }

    //挿入位置を求めるために二分探索
    func binarySearch(rank:Int)->Int?{
        var low = 0
        var high = itemArray.count - 1
        while (true) {
            //真ん中を取り出す
            let mid = (low + high) / 2
            //値をとりだす
            let value = itemArray[mid].rank
            print(value)
            print(rank)
            //とりだした値が、探したい値よりおおきいかちいさいかをしらべる
            if value == rank {
                return mid
            }else if low>high{
                return nil
            } else if value < rank {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
    }

}

// アイテムの型、ToDo項目のtitleとチェック(done)の有無
class Item: Object  {
    @objc dynamic var title = ""
    @objc dynamic var done = false
    @objc dynamic var rank = 0
}
