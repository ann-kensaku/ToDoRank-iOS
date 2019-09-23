//
//  AddNewItemViewController.swift
//  ToDoRank-iOS
//
//  Created by yuki on 2019/09/13.
//  Copyright © 2019 yuki. All rights reserved.
//

import UIKit
import RealmSwift

class AddNewItemViewController: UIViewController {

    @IBOutlet weak var flickLabel: UILabel!
    @IBOutlet weak var compareLabel: UILabel!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    
    //Realmをインスタンス化
    let realm = try! Realm()
    // このDB内の唯一の配列に作ったアイテムを追加していく
    var itemList: List<Item>!
    //比較における考慮する範囲,Highの程、上にある=小さいから注意
    var rangeRankHigh = 0
    var rangeRankLow = 10
    //flickボタンの初期座標
    var firstFlickPoint = CGPoint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //スワイプで前画面に戻る処理を禁止。high&lowのフリップで誤作動することがあったので
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        //途中までのフリックに対応（元の場所にラベルが戻れるように保存）
        firstFlickPoint = flickLabel.frame.origin
        //db内のWrapedItemクラスの中の1つの実体の配列でitemをやり取りする
        itemList = realm.objects(WrapedItem.self).first?.list
        //flicklabelの文字の大きさを自動調整
        flickLabel.adjustsFontSizeToFitWidth = true
        //comparelabelの文字の大きさを自動調整
        compareLabel.adjustsFontSizeToFitWidth = true
        //labelを動かせるように
        flickLabel.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rangeRankLow = itemList.count - 1
        //ポップアップで追加するitemを入力。itemListが空っぽだったならば、入れた瞬間即元画面に遷移
        addPopup()
    }
    // このviewに遷移した直後に項目名を入れるためのポップアップ
    func addPopup() {
        //追加するアイテムの名前入れる
        var nameTextField = UITextField()
        //popup、かっこいい
        let alert = UIAlertController(title: "新しいアイテムを追加", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "リストに追加", style: .default) { (action) in
            if (nameTextField.text ?? "").count > 0{
                //フリックのラベルに追加するitemの名前を入れる
                self.flickLabel.text = nameTextField.text!
                //最初の1個目なら文句なしにデータベースに入れる
                if (self.itemList.count == 0){
                    // 追加されるアイテム
                    let newItem = Item()
                    newItem.title = nameTextField.text!
                    
                    try! self.realm.write{
                        // アイテム追加処理
                        self.itemList.append(newItem)
                    }
                    let nav = self.navigationController
                    // 一つ前のViewControllerを取得する
                    let toDoRankViewController = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! ToDoRankViewController
                    // 前のviewのcellを更新（挿入）
                    toDoRankViewController.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    
                    //前の画面に戻る
                    self.navigationController?.popViewController(animated: true)
                }else{//最初の一個でなければcomparelabelに基準のを書き込む
                    self.compareLabel.text = self.itemList[(self.rangeRankLow+self.rangeRankHigh)/2].title
                }
            } else {//入力されなきゃ何もせずに前の画面に遷移
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "新しいアイテム"
            //text内容じゃなくてそのものが同一だからセーフ
            nameTextField = alertTextField
        }
        
        alert.addAction(action)
        //かっこいい
        present(alert, animated: true, completion: nil)
        
      
    }
    //rangeRankLowとrangeRankHighのmidを基準に二分探索、
    //rangeRankLowとrangeRankHighの更新、または、dbとtableへの挿入と反映を行う
    func binarySearch(isHigh: Bool){
        //midより重要ならば
        if(isHigh){
            //...[][][NEW!!][rangeHigh=rangeLow][(or)rangeLow][]....ならばこの位置は0から数えてrangeHigh番目なので
            //rangeMaxに新しいitemを挿入
            if(rangeRankHigh == (rangeRankLow + rangeRankHigh)/2){
                let newItem = Item()
                newItem.title = flickLabel.text!
                newItem.rank = rangeRankHigh
                try! self.realm.write{
                    for i in rangeRankHigh..<self.itemList.count{
                        self.itemList[i].rank += 1
                    }
                    // アイテム追加処理
                    self.itemList.insert(newItem, at: rangeRankHigh)
                }
                //前の画面に戻る準備
                let nav = self.navigationController
                // 一つ前のViewControllerを取得する
                let toDoRankViewController = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! ToDoRankViewController
                // 前のviewのcellを更新（挿入）
                toDoRankViewController.tableView.insertRows(at: [IndexPath(row: rangeRankHigh, section: 0)], with: .automatic)
                //前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            }else{//下限を更新して上げる
                rangeRankLow = (rangeRankHigh+rangeRankLow)/2 - 1
            }
        }else{//midより要らない子なら//...[][][rangeLow=rangeHigh][NEW!!][][]....ならばこの位置は0から数えてrangeHigh+1番目なので
            //rangeMaxに新しいitemを挿入
            if(rangeRankLow == rangeRankHigh){
                let newItem = Item()
                newItem.title = flickLabel.text!
                newItem.rank = rangeRankLow + 1
                try! self.realm.write{
                    for i in (rangeRankLow + 1)..<self.itemList.count{
                        self.itemList[i].rank +=  1
                    }
                    // アイテム追加処理
                    self.itemList.insert(newItem, at: rangeRankHigh+1)
                }
                let nav = self.navigationController
                // 一つ前のViewControllerを取得する
                let toDoRankViewController = nav?.viewControllers[(nav?.viewControllers.count)!-2] as! ToDoRankViewController
                // 値を渡す
                toDoRankViewController.tableView.insertRows(at: [IndexPath(row: rangeRankHigh+1, section: 0)], with: .automatic)
                //前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            }else{//上限を更新して下げる
                rangeRankHigh = (rangeRankHigh+rangeRankLow)/2 + 1
            }
        }
    }

    //指の動きとラベルの動きを連動させる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        let touchEvent = touches.first!
        // ドラッグ前のx座標
        let preDx = touchEvent.previousLocation(in: self.view).x
        // ドラッグ後のx座標
        let newDx = touchEvent.location(in: self.view).x
        // ドラッグしたx座標の移動距離
        let dx = newDx - preDx
        
        if(newDx > self.view.frame.width*3/4){//もしも、指を離して右を選択する範囲内なら
            highLabel.shadowOffset = CGSize(width: 10,height: 10)
            highLabel.shadowColor = .red
        }else if(newDx < self.view.frame.width/4){//もしも、指を離して左を選択する範囲内なら
            lowLabel.shadowOffset = CGSize(width: 10,height: 10)
            lowLabel.shadowColor = .cyan
        }else{//もしも、どちらからも範囲外なら
            highLabel.shadowOffset = CGSize(width: 0,height: 0)
            lowLabel.shadowOffset = CGSize(width: 0,height: 0)
        }
        // 移動分を反映させる
        flickLabel.frame.origin.x += dx
    }
    //指を離した時に、ラベルが指定範囲内まで移動していたら、high&low選択をしたとして、次の比較or挿入を実行
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if(flickLabel.frame.origin.x > self.view.frame.width*3/4 - flickLabel.frame.width/2){//もしも、指を離して左を選択する範囲内なら
            binarySearch(isHigh: true)
            compareLabel.text = itemList[(rangeRankHigh+rangeRankLow)/2].title
        }else if(flickLabel.frame.origin.x < self.view.frame.width/4  -  flickLabel.frame.width/2){//もしも、指を離して右を選択する範囲内なら
            binarySearch(isHigh: false)
            compareLabel.text = itemList[(rangeRankHigh+rangeRankLow)/2].title
        }else{//もしも、どちらからも範囲外なら何もしない
        }
        flickLabel.frame.origin = firstFlickPoint
        highLabel.shadowOffset = CGSize(width: 0,height: 0)
        lowLabel.shadowOffset = CGSize(width: 0,height: 0)
    }
}



