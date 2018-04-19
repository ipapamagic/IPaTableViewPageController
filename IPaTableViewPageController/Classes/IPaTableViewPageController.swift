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
    
    @objc optional func createNoDataCell(forPageController:IPaTableViewPageController) -> UITableViewCell
    
    func loadData(forPageController:IPaTableViewPageController,  page:Int, complete:@escaping ([Any],Int,Int)->())
    func configureCell(forPageController:IPaTableViewPageController,cell:UITableViewCell,indexPath:IndexPath,data:Any)
    func configureLoadingCell(forPageController:IPaTableViewPageController,cell:UITableViewCell,indexPath:IndexPath)
}

open class IPaTableViewPageController : NSObject,UITableViewDataSource {
    var totalPageNum = 1
    var currentPage = 0
    var currentLoadingPage = -1
    var datas = [Any]()
    var hasLoadingCell = false
    var hasNoDataCell = false
    open var insertAnimation = true
    open var noLoadingCellAtBegining = false
    open var enableNoDataCell = false
    open var dataCount:Int {
        get {
            return datas.count
        }
    }
    open var delegate:IPaTableViewPageControllerDelegate!
    open func getData(index:Int) -> Any? {
        return (datas.count <= index) ? nil : datas[index]
    }
    open func reloadAllData() {
        totalPageNum = 1;
        currentPage = 0;
        currentLoadingPage = -1;
        datas.removeAll(keepingCapacity: true)
        let tableView = delegate.tableView(forPageController: self)
        tableView.reloadData()
    }
    open func loadNextPage() {
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
                    indexList.append(IndexPath(row: startRow + idx, section: 0))
                }
                self.datas = self.datas + newDatas
                DispatchQueue.main.async {
                    let tableView = self.delegate.tableView(forPageController:self)
                    
                    if self.insertAnimation {
                        tableView.beginUpdates()
                        if self.currentPage == self.totalPageNum {
                            if self.currentPage == 0 && self.hasNoDataCell {
                                tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                                self.hasNoDataCell = false
                            }
                            else if self.hasLoadingCell {
                                tableView.deleteRows(at: [IndexPath(row: startRow, section: 0)], with: .automatic)
                            }
                        }
                        else if !self.hasLoadingCell {
                            //add back loading cell
                            indexList.append(IndexPath(row: startRow + newDatas.count, section: 0))
                        }
                        
                        
                        if indexList.count > 0 {
                            tableView.insertRows(at: indexList, with: .automatic)
                        }
                        if self.currentPage != self.totalPageNum {
                            tableView.endUpdates() //need to call before reloadRows
                            tableView.reloadRows(at: [IndexPath(row: self.datas.count, section: 0)], with: .automatic)
                        }
                        else {
                            if self.enableNoDataCell && self.datas.count == 0 && self.currentPage == 1 && self.totalPageNum == 1 {
                                tableView.insertRows(at: [IndexPath(row:0,section:0)], with: .automatic)
                                self.hasNoDataCell = true
                            }
                            
                            tableView.endUpdates() //need to call after insert new rows
                        }
                    }
                    else {
                        if self.currentPage == self.totalPageNum {
                            if self.currentPage == 0 && self.hasNoDataCell {
                              
                                self.hasNoDataCell = false
                            }
                        
                            if self.enableNoDataCell && self.datas.count == 0 && self.currentPage == 1 && self.totalPageNum == 1 {
                             
                                self.hasNoDataCell = true
                            }
                        }
                        tableView.reloadData()
                    }
                }
            })
            
        }
    }
    open func isLoadingCell(_ indexPath:IndexPath) -> Bool {
        return Bool(indexPath.row == datas.count && currentPage != totalPageNum)
    }
    open func isNoDataCell(_ indexPath:IndexPath) -> Bool {
        return Bool(indexPath.row == 0 && datas.count == 0 && currentPage == totalPageNum && totalPageNum == 1)
    }
    // MARK:Table view data source
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        hasLoadingCell = false
        if currentPage == 0 && noLoadingCellAtBegining {
            return 0
        }
        if currentPage == totalPageNum {
            if (datas.count == 0 && enableNoDataCell) {
                return 1
            }
            return datas.count
        }
        hasLoadingCell = true
        return datas.count + 1
    }
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        if isNoDataCell(indexPath) {
            cell = delegate.createNoDataCell!(forPageController: self)
        }
        else if isLoadingCell(indexPath) {
            cell = delegate.createLoadingCell(forPageController:self, indexPath: indexPath)
            self.loadNextPage()
            delegate.configureLoadingCell(forPageController:self, cell: cell, indexPath: indexPath)
        }
        else {
            cell = delegate.createDataCell(forPageController:self, indexPath: indexPath)
            delegate.configureCell(forPageController:self, cell: cell, indexPath: indexPath, data: datas[indexPath.row])
            
        }
        return cell
    }
    


    
}
