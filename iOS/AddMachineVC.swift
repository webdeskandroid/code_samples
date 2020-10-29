//
//  AddMachineVC.swift
//
//  Created by Mobile Team on 29/06/18.
//  Copyright © 2018 Mobile Team. All rights reserved.
//

import UIKit

import SDWebImage

class AddMachineVC: UIViewController {

    var sections = sectionsData

    @IBOutlet weak var tableView:UITableView!
    weak var selectedStyle:MachineProduct!
    weak var selectedBrand:MachineProduct!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Auto resizing the height of the cell
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.getStyleList()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Buttons events
    
    @IBAction func didClickBtnBack(sender:UIButton){
        
        if selectedStyle == nil{
            self.navigationController?.popViewController(animated: true)
        }else{
            let alertController = UIAlertController(title: "", message: "Are you sure want to back without add machine?", preferredStyle: UIAlertControllerStyle.alert)
            let yes = UIAlertAction(title: "KEEP", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                //The (withIdentifier: "VC2") is the Storyboard Segue identifier.
                self.dismiss(animated: true, completion: nil)
            })
            let no = UIAlertAction(title: "DISCARD", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                //The (withIdentifier: "VC2") is the Storyboard Segue identifier.
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            })
            
            alertController.addAction(yes)
            alertController.addAction(no)
            self.present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func didClickBtnSave(sender:UIButton){
        var serialNumber:MachineProduct!
        for items in self.sections[2].items{
            if items.isSelected == true{
                serialNumber = items as! SerialNumber
                break
            }
        }
        
        if serialNumber == nil{
            self.view.showToastMessgae(message: "Please select product from list or choose another Style and Brand")
            return
        }
        if serialNumber.parts.count > 0{
            if Reachability.isConnectedToNetwork() == false {
                self.view.showToastMessgae(message: Helper.sharedInstance.getLocalizedString(key: Constant.ErrorMessage.InternetNotAvailable))
                return
            }
            Helper.sharedInstance.showProgress(controller: self)
            let userDetails = UserDefaults.standard.getCurrentLoginUserID()
            let dictRequestData = ["product_id":serialNumber.strID,"customer_id":userDetails] as! [String:String]
            ApiHandler.checkALertPart(strRequest: "test/index.php/check", dictParameter: dictRequestData, withCompleation: {(json, error) in
                Helper.sharedInstance.hideProgress(controller: self)
//                https://staging.webdesksolution.com/test/index.php/check
                if error != nil{
                    print(error?.localizedDescription)
                }
                else{
                    print(json?.dictionaryValue)
                    if json?.dictionaryValue["response"]?.dictionaryValue["code"]?.intValue == 1{
                        let objSetAlertVC = Constant.STORYBOARD.instantiateViewController(withIdentifier: "AddAlertVC") as! AddAlertVC
                        objSetAlertVC.objSectionData = self.sections
                        self.navigationController?.pushViewController(objSetAlertVC, animated: true)
                    }else{
                        self.view.showToastMessgae(message:(json?.dictionaryValue["response"]?.dictionaryValue["error"]!.stringValue)!)
                    }
                }
            })
        }
        else{
            print("This product has no parts available.")
             self.view.showToastMessgae(message:"This product has no parts available.")
        }
    }
    
    @objc func didClickFindSerialNumber(sender:UIButton){
        if let cell = sender.superview?.superview as? FindMachineCell{
            if cell.textField.text == ""{
                self.findPartsWithSerialNumber()
            }else{
                self.findParts(serialNumber: cell.textField.text!)
            }
        }
    }
    
    //MARK: Api calls
    
    func getStyleList(){
//        https://staging.webdesksolution.com/
        if Reachability.isConnectedToNetwork() == false {
            self.view.showToastMessgae(message: Helper.sharedInstance.getLocalizedString(key: Constant.ErrorMessage.InternetNotAvailable))
            return
        }

        Helper.sharedInstance.showProgress(controller: self)
        ApiHandler.getMachineStyleList(strUrlEndPOint: "test/index.php/services/machinefilter") { (json, error) in
            
            Helper.sharedInstance.hideProgress(controller: self)
            
            if error != nil{
                print(error?.localizedDescription)
            }
            else{
                print(json?.dictionaryValue)
                self.sections[0].items.removeAll()
                if let arrStyleJson = json?.dictionaryValue["response"]?.dictionaryValue["message"]?.dictionaryValue["style"]?.dictionaryValue["data"]?.arrayValue{
                    for (item) in arrStyleJson{
                        self.sections[0].items.append(MachineStyle.init(id: item.dictionaryValue["id"]!.stringValue, name: item.dictionaryValue["lable"]!.stringValue))
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func getStyleBrandList(strStyleID:String){
        //    https://staging.webdesksolution.com/
        if Reachability.isConnectedToNetwork() == false {
            self.view.showToastMessgae(message: Helper.sharedInstance.getLocalizedString(key: Constant.ErrorMessage.InternetNotAvailable))
            return
        }
        
        Helper.sharedInstance.showProgress(controller: self)
        ApiHandler.getMachineBrandList(strUrlEndPOint: "test/index.php/services/machinefilter?style=\(strStyleID)") { (json, error) in
            
            Helper.sharedInstance.hideProgress(controller: self)
            if error != nil {
                print(error?.localizedDescription)
            }
            else{
                print(json?.dictionaryValue)
                if let objBrandJson = json?.dictionaryValue["response"]?.dictionaryValue["message"]?.dictionaryValue["brand"]
                {
                     let totalProduct = objBrandJson.dictionaryValue["total_products"]?.stringValue
                    if totalProduct == "1"{
                        let objSerialNumber = SerialNumber.init(id: objBrandJson.dictionaryValue["single_product"]!.dictionaryValue["id"]!.stringValue, name: objBrandJson.dictionaryValue["single_product"]!.dictionaryValue["name"]!.stringValue)
                        objSerialNumber.strDescription = objBrandJson.dictionaryValue["single_product"]!.dictionaryValue["sku"]!.stringValue
                        objSerialNumber.imageThumbURL = objBrandJson.dictionaryValue["single_product"]!.dictionaryValue["image"]!.stringValue
                        objSerialNumber.parts = objBrandJson.dictionaryValue["single_product"]!.dictionaryValue["parts"]
                        self.sections[2].items = [objSerialNumber]
//                        self.tableView.reloadData()
                        self.sections[2].collapsed = false
                    }
                    else{
                        self.sections[2].items = [SerialNumber(id: "", name: "")]
                        self.sections[2].collapsed = true
                    }
                    
                    
                    let isSerialNumberAvailable = objBrandJson.dictionaryValue["isSerialNumberSupported"]?.boolValue
                    
                    self.sections[1].items.removeAll()
                    if let arrStyleJson = json?.dictionaryValue["response"]?.dictionaryValue["message"]?.dictionaryValue["brand"]?.dictionaryValue["data"]?.arrayValue
                    {
                        for (item) in arrStyleJson
                        {
                            self.sections[1].items.append(Brand.init(id: item.dictionaryValue["id"]!.stringValue, name: item.dictionaryValue["lable"]!.stringValue))
                        }
                        if self.sections[1].items.count == 1{
                            self.sections[1].items.first?.isSelected = true
                            self.sections[1].items.first?.selectText = self.sections[1].items.first?.strName
                            self.sections[1].name = self.sections[1].title+"(\(self.sections[1].items.first!.selectText!))"
                            self.sections[1].collapsed = false
                            self.tableView.reloadData()
                            self.sections[1].collapsed = true
                            self.sections[0].collapsed = true
                            if isSerialNumberAvailable == true && (totalProduct != "1" || totalProduct != "0"){
                                 self.sections[2].collapsed = false
                            }
                            self.tableView.reloadData()
                            return
                        }else if self.sections[1].items.count == 0{
                            self.sections[1].name = self.sections[1].title
                            self.sections[1].items = [Brand.init(id: "", name: "No Data Found !")]
                        }
                    }
                    else
                    {
                        self.sections[1].name = self.sections[1].title
                        self.sections[1].items = [Brand.init(id: "", name: "No Data Found !")]
                    }
                    self.tableView.reloadData() //TODO: Patch for cell not update Need to fix
                    self.sections[1].collapsed = false
                    self.sections[0].collapsed = true
                    self.tableView.reloadData()  //TODO: Patch for cell not update Need to fix
                }
            }
        }
    }
    
    func findPartsWithSerialNumber(){
        //https://staging.webdesksolution.com/test/index.php/services/machinefilter?style=357&currentPage=1&brand=503&type=listing&pageSize=5
        if Reachability.isConnectedToNetwork() == false {
            self.view.showToastMessgae(message: Helper.sharedInstance.getLocalizedString(key: Constant.ErrorMessage.InternetNotAvailable))
            return
        }
        if self.selectedStyle == nil{
            self.view.showToastMessgae(message: "Please enter serial number.")
            return
        }
        Helper.sharedInstance.showProgress(controller: self)
        ApiHandler.getParts(strUrlEndPOint: "test/index.php/services/machinefilter?style=\(self.selectedStyle?.strID! ?? "")&currentPage=1&brand=\(self.selectedBrand?.strID! ?? "")&type=listing&pageSize=5") { (json, error) in
            Helper.sharedInstance.hideProgress(controller: self)
            print(json?.dictionaryValue)
            if error == nil{
                if let arrPartsJson = json?.dictionaryValue["response"]?.dictionaryValue["message"]?.dictionaryValue["data"]?.arrayValue{
                    self.sections[2].items.removeAll()
                    for objBrandJson in arrPartsJson{
                        let objSerialNumber = SerialNumber.init(id: objBrandJson.dictionaryValue["id"]!.stringValue, name: objBrandJson.dictionaryValue["name"]!.stringValue)
                        objSerialNumber.strDescription = objBrandJson.dictionaryValue["sku"]!.stringValue
                        objSerialNumber.imageThumbURL = objBrandJson.dictionaryValue["image"]!.stringValue
                        objSerialNumber.parts = objBrandJson.dictionaryValue["parts"]
                        self.sections[2].items.append(objSerialNumber)
                    }
                    self.tableView.reloadData()
                }
            }
            print(json?.dictionaryValue)
        }
    }
    
    func findParts(serialNumber:String){
        // https://staging.webdesksolution.com/test/index.php/services/machinefilter?style=527&serical_number=fjthjy&brand=500

        if Reachability.isConnectedToNetwork() == false {
            self.view.showToastMessgae(message: Helper.sharedInstance.getLocalizedString(key: Constant.ErrorMessage.InternetNotAvailable))
            return
        }
        
        Helper.sharedInstance.showProgress(controller: self)
        ApiHandler.getPartsWithSerialNumber(strUrlEndPOint: "test/index.php/services/machinefilter?style=\(self.selectedStyle.strID)&serical_number=\(serialNumber)&brand=\(self.selectedBrand.strID)") { (json, error) in
            Helper.sharedInstance.hideProgress(controller: self)
            print(json?.dictionaryValue)
            
            if error == nil{
                if let arrPartsJson = json?.dictionaryValue["response"]?.dictionaryValue["message"]?.dictionaryValue["data"]?.arrayValue{
                    self.sections[2].items.removeAll()
                    for objBrandJson in arrPartsJson{
                        let objSerialNumber = SerialNumber.init(id: objBrandJson.dictionaryValue["id"]!.stringValue, name: objBrandJson.dictionaryValue["name"]!.stringValue)
                        objSerialNumber.strDescription = objBrandJson.dictionaryValue["sku"]!.stringValue
                        objSerialNumber.imageThumbURL = objBrandJson.dictionaryValue["image"]!.stringValue
                        self.sections[2].items.append(objSerialNumber)
                    }
                    self.tableView.reloadData()
                }
            }
         }
    }
}

//
// MARK: - View Controller DataSource and Delegate
//
extension AddMachineVC:UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].collapsed ? 0 : sections[section].items.count
    }
    
    // Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == sections.count - 1{
            if self.sections[indexPath.section].items.count > 0 && self.sections[indexPath.section].items[indexPath.row].strName != ""{
                let cell = tableView.dequeueReusableCell(withIdentifier: "SerialNumberCellID") as! SerialNumberCell
            
                let item = sections[indexPath.section].items[indexPath.row]
                cell.lblText?.numberOfLines = 0
                cell.lblText?.lineBreakMode = .byWordWrapping
                
                cell.lblText?.text = item.strName
                cell.lblDetails?.text = item.strDescription
                cell.imgViewParts?.image = #imageLiteral(resourceName: "noImage")
                cell.imgViewParts?.sd_setImage(with: URL.init(string: item.imageThumbURL), completed: { (image, error, type, url) in
                
                })
//                cell.selectionStyle = .none
                if item.isSelected == true
                {
                    cell.accessoryType = .checkmark
//                    sections[indexPath.section].name = sections[indexPath.section].title+"(\(item!.selectText!))"
                }
                else{
                    cell.accessoryType = .none
                }
                
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "FindMachineCellID") as! FindMachineCell
                cell.selectionStyle = .none
                cell.btnFindSerialNumber.addTarget(self, action: #selector(self.didClickFindSerialNumber(sender:)
                    ), for: .touchUpInside)
                return cell
            }
        }
        else{
            let cell: CollapsibleTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? CollapsibleTableViewCell ??
                CollapsibleTableViewCell(style: .default, reuseIdentifier: "cell")
            let item = sections[indexPath.section].items?[indexPath.row]
            //        cell.nameLabel.text = item.strID
            cell.detailLabel.text = item?.strName
            cell.selectionStyle = .none
            if item?.isSelected == true
            {
                cell.accessoryType = .checkmark
                sections[indexPath.section].name = sections[indexPath.section].title//+"(\(item!.selectText!))"
            }
            else{
                cell.accessoryType = .none
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        header.titleLabel.text = sections[section].name
        header.arrowLabel.text = "+"
        header.setCollapsed(sections[section].collapsed)
        
        header.section = section
        header.delegate = self
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if indexPath.section == 2{
            let objSerialNumber = sections[indexPath.section].items[indexPath.row]
            let foundItem = sections[indexPath.section].items.index(of: objSerialNumber)
            let selectedSerialNumber = sections[indexPath.section].items[foundItem!]
            if selectedSerialNumber.isSelected == true{
                sections[indexPath.section].items[indexPath.row].isSelected = false
            }else{
                for item in sections[indexPath.section].items{
                    item.isSelected = false
                }
                sections[indexPath.section].items[indexPath.row].isSelected = true
            }
        }else{
            for item in sections[indexPath.section].items{
                item.isSelected = false
            }
            sections[indexPath.section].items[indexPath.row].isSelected = true
        }
        sections[indexPath.section].items[indexPath.row].selectText = sections[indexPath.section].items[indexPath.row].strName
        if let brand = sections[indexPath.section].items[indexPath.row] as? Brand{
            selectedBrand = brand
        }
        if let style = sections[indexPath.section].items[indexPath.row] as? MachineStyle{
            selectedStyle = style
        }

        if indexPath.section == 0{
            self.getStyleBrandList(strStyleID: sections[indexPath.section].items[indexPath.row].strID!)
        }
        if indexPath.section == 1{
            self.sections[2].items = [SerialNumber(id: "", name: "")]
            self.sections[2].collapsed = false
            self.sections[1].collapsed = true
            self.sections[1].name = self.sections[1].title+"(\(sections[indexPath.section].items[indexPath.row].selectText!))"
            self.findPartsWithSerialNumber()
        }

        sections[indexPath.section].items[indexPath.row].selectText = sections[indexPath.section].items[indexPath.row].strName
        tableView.reloadData()
    }
}

//
// MARK: - Section Header Delegate
//
extension AddMachineVC: CollapsibleTableViewHeaderDelegate {
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        let collapsed = !sections[section].collapsed
        // Toggle collapse
        sections[section].collapsed = collapsed
        header.setCollapsed(collapsed)
        tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
    }
}