//
//  IPaTableViewPageController.swift
//  IPaPageControlTableViewController
//
//  Created by IPa Chen on 2015/7/24.
//  Copyright (c) 2015年 A Magic Studio. All rights reserved.
//

import UIKit

@objc public protocol IPaTableViewPageControllerDelegate {
    func tableView(forPageController:IPaTableViewPageController) -> UITableView
    func createLoadingCell(forPageController:IPaTableViewPageController, indexPath:IndexPath) -> UITableViewCell
    func createDataCell(forPageController:IPaTableViewPageController, indexPath:IndexPath) -> UITableViewCell
    func loadData(forPageController:IPaTableViewPageController,  page:Int, complete:@escaping ([Any],Int,Int)->())
    func configureCell(forPageController:IPaTableViewPageController,cell:UITableViewCell,indexPath:IndexPath,data:Any)
    func configureLoadingCell(forPageController:IPaTableViewPageController,cell:UITableViewCell,indexPath:IndexPath)
}

open class IPaTableViewPageController : NSObject,UITableViewDataSource {
    var totalPageNum = 1
    var currentPage = 0
    var currentLoadingPage = -1
    var datas = [Any]()
    open var dataCount:Int {
        get {
            return datas.count
        }
    }
    open var delegate:IPaTableViewPageControllerDelegate!
    public func getData(index:Int) -> Any? {
        return (datas.count <= index) ? nil : datas[index]
    }
    public func reloadAllData() {
        totalPageNum = 1;
        currentPage = 0;
        currentLoadingPage = -1;
        datas.removeAll(keepingCapacity: true)
        let tableView = delegate.tableView(forPageController: self)
        tableView.reloadData()
    }
    func isLoadingCell(_ indexPath:IndexPath) -> Bool {
        return Bool(indexPath.row == datas.count)
    }
    // MARK:Table view data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentPage == totalPageNum {
            return datas.count
        }
        return datas.count + 1
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if isLoadingCell(indexPath) {
            cell = delegate.createLoadingCell(forPageController:self, indexPath: indexPath)
            if (currentLoadingPage != currentPage + 1) {
                currentLoadingPage = currentPage + 1;
                delegate.loadData(forPageController:self, page: currentLoadingPage, complete: {
                    newDatas,totalPage,currentPage in
                    self.totalPageNum = totalPage
                    if currentPage != self.currentLoadingPage {
                        return
                    }
                    self.currentPage = self.currentLoadingPage
                    self.currentLoadingPage = -1
                    var indexList = [IndexPath]()
                    let startRow = self.datas.count
                    for idx in 0..<newDatas.count {
                        indexList.append(IndexPath(row: startRow + idx, section: indexPath.section))
                    }
                    self.datas = self.datas + newDatas
                    DispatchQueue.main.async {
                        let tableView = self.delegate.tableView(forPageController:self)
                        tableView.beginUpdates()
                        if self.currentPage == self.totalPageNum {
                            tableView.deleteRows(at: [IndexPath(row: startRow, section: indexPath.section)], with: .automatic)
                        }
                        if indexList.count > 0 {
                            tableView.insertRows(at: indexList, with: .automatic)
                        }
                        tableView.endUpdates()
                        if self.currentPage != self.totalPageNum {
                            tableView.reloadRows(at: [IndexPath(row: self.datas.count, section: indexPath.section)], with: .automatic)
                        }
                    }
                })
                
            }
            delegate.configureLoadingCell(forPageController:self, cell: cell, indexPath: indexPath)
        }
        else {
            cell = delegate.createDataCell(forPageController:self, indexPath: indexPath)
            delegate.configureCell(forPageController:self, cell: cell, indexPath: indexPath, data: datas[indexPath.row])
            
        }
        return cell
    }
    


    
}
