//
//  ToDoListViewController.swift
//  ToDoRank-iOS
//
//  Created by yuki on 2019/08/17.
//  Copyright © 2019 yuki. All rights reserved.
//

import RealmSwift
import UIKit

class ToDoRankViewController: UITableViewController {
    //Realmをインスタンス化
    let realm = try! Realm()
    // このDB内の唯一の配列に作ったアイテムを追加していく
    var itemList: List<Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //もしもwrapedItemが空っぽならば、実態を作る。
        if(realm.objects(WrapedItem.self).count == 0){
            let newWrapedItem = WrapedItem()
            try! realm.write{
                realm.add(newWrapedItem)
            }
        }
        //基本はこの実態のlistに要素を入れていく
        itemList = realm.objects(WrapedItem.self).first?.list
    }
    
    // セルの数が指itemArray（の長さ）によって指定される
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemList.count
    }
    
    //それぞれのセルについてどーするか
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Main.storybordのToDoItemCellがここのcell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoCell", for: indexPath)
        let item = itemList[indexPath.row]
        
        cell.textLabel?.text = item.title
        //doneがtrueならチェックマーク、falseならなし
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    // 選択されたセルに実行される処理
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        try! self.realm.write {
            // チェックマーク
            itemList[indexPath.row].done = !itemList[indexPath.row].done
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
                        self.itemList[indexPath.row].title = textField.text!
                    }
                    // リロードしてUIに反映
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                } else {//入力されなきゃ何もしない
                }
            }
            
            alert.addTextField { (alertTextField) in
                //元の名前が入ってる
                alertTextField.placeholder = self.itemList[indexPath.row].title
                //text内容じゃなくてそのものが同一だからセーフ
                textField = alertTextField
                
            }
            alert.addAction(add_action)
            //かっこいい
            self.present(alert, animated: true, completion: nil)
            
        }
        edit_action.backgroundColor = UIColor.lightGray
        
        let delete_action = UITableViewRowAction(style: .default, title: "Delete"){ (action, indexPath) in
            
            try! self.realm.write {
                //削除対象より下のrankを1上げる（だから配列的に上がるので-1する）
                for i in (indexPath.row + 1)..<self.itemList.count{
                    self.itemList[i].rank -=  1
                }
                //データベース上の削除
                self.itemList.remove(at:indexPath.row)
            }
            //表示上のアイテム削除処理
            let indexPaths = [indexPath]
            tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        
        return [delete_action,edit_action]
    }
    
    //挿入位置を求めるために二分探索
    func binarySearch(rank:Int)->Int?{
        var low = 0
        var high = itemList.count - 1
        while (true) {
            //真ん中を取り出す
            let mid = (low + high) / 2
            //値をとりだす
            let value = itemList[mid].rank
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

class WrapedItem: Object{
    let list = List<Item>()
}
// アイテムの型、ToDo項目のtitleとチェック(done)の有無
class Item: Object  {
    @objc dynamic var title = ""
    @objc dynamic var done = false
    @objc dynamic var rank = 0
}
