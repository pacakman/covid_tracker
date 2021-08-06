//
//  ViewController.swift
//  covid_tracker
//
//  Created by Idris on 21/06/2021.
//

import UIKit
import Charts

class ViewController: UIViewController {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .default
        formatter.usesGroupingSeparator = true
        formatter.locale = .current
        formatter.groupingSeparator = ","
        return formatter
    }()
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    private var scope: APICaller.DataScope = .national
    private var dayData: [DayData] =  [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.createGraph()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Covid Cases"
        configureTableView()
        createFilterButton()
        fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    private func createGraph() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width / 1.5))
        headerView.clipsToBounds = true
        
        var entries: [BarChartDataEntry] = []
        for index in 0..<dayData.count {
            let item = dayData[index]
            entries.append(.init(x: Double(index), y: Double(item.count)))
        }
        let dataSet = BarChartDataSet(entries: entries)
        dataSet.colors = ChartColorTemplates.joyful()
        let data = BarChartData(dataSet: dataSet)
        let chart = BarChartView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width / 1.5))
        chart.data = data
        headerView.addSubview(chart)
        self.tableView.tableHeaderView = headerView
    }
    
    private func configureTableView() {
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    
    private func fetchData() {
        APICaller.shared.getCovidData(for: self.scope) { (result) in
            switch result {
            case .success(let result):
                self.dayData = result
                break
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    
    private func createFilterButton() {
        let buttonTitle: String = {
            switch scope {
            case .national:
                return "National"
            case .state(let state):
                return state.name
            }
        }()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: buttonTitle, style: .done, target: self, action: #selector(didTapFilter))
    }
    
    
    @objc private func didTapFilter() {
        let vc = FilterViewController()
        vc.completion = {[weak self] state in
            self?.scope = .state(state)
            self?.fetchData()
            self?.createFilterButton()
        }
        let navVC = UINavigationController(rootViewController: vc)
        self.present(navVC, animated: true, completion: nil)
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.dayData[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = createText(with: data)
        return cell
    }
    
    private func createText(with data: DayData) -> String? {
        let dateString = DateFormatter.prettyFormatter.string(from: data.date)
        let total = Self.numberFormatter.string(from: NSNumber(value: data.count))
        return "\(dateString): \(total ?? String(data.count))"
    }
}
