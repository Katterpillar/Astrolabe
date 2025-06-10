//
//  LoaderDecoratorSource.swift
//  Astrolabe
//
//  Created by Sergei Mikhan on 2/4/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift

open class LoaderDecoratorSource<DecoratedSource: ReusableSource>: LoaderReusableSource {

  public typealias Container = DecoratedSource.Container

  public required init() {
    internalInit()
  }
  public var containerView: Container? {
    get { return source.containerView }
    set { source.containerView = newValue }
  }
  public var hostViewController: UIViewController? {
    get { return source.hostViewController }
    set { source.hostViewController = newValue }
  }
  public var sections: [Sectionable] {
    get { return source.sections }
    set { source.sections = newValue }
  }
  public var selectedCellIds: Set<String> {
    get { return source.selectedCellIds }
    set { source.selectedCellIds = newValue }
  }
  public var selectionBehavior: SelectionBehavior {
    get { return source.selectionBehavior }
    set { source.selectionBehavior = newValue }
  }
  public var selectionManagement: SelectionManagement {
    get { return source.selectionManagement }
    set { source.selectionManagement = newValue }
  }

  public func registerCellsForSections() {
    source.registerCellsForSections()
  }

  public var startProgress: ProgressClosure?
  public var stopProgress: ProgressClosure?
  public var noDataState: NoDataStateClosure?
  public var updateEmptyView: EmptyViewClosure?
  public var autoupdatePeriod = defaultReloadInterval
  public var loadingBehavior = LoadingBehavior.initial {
    didSet {
      if loadingBehavior.contains(.autoupdate) {
        switch state {
        case .notInitiated: break
        default: startAutoupdateIfNeeded()
        }
      } else {
        timerDisposeBag = nil
      }
    }
  }
  public var lastCellDisplayed: VoidClosure?
  public var lastCellСondition: LastCellConditionClosure?

  public let source = DecoratedSource()
  fileprivate var loaderDisposeBag: DisposeBag?
  fileprivate var timerDisposeBag: DisposeBag?
  fileprivate var state = LoaderState.notInitiated
  public var loader: LoaderMediatorProtocol?

  fileprivate func internalInit() {
    self.source.lastCellDisplayed = { [weak self] in
      self?.lastCellDisplayed?()
      self?.handleLastCellDisplayed()
    }
    self.source.lastCellСondition = { [weak self] in
      return self?.lastCellСondition?($0, $1, $2) ?? false
    }
  }

  public func forceReloadData(keepCurrentDataBeforeUpdate: Bool) {
    load(.force(keepData: keepCurrentDataBeforeUpdate))
  }

  public func forceLoadNextPage() {
    load(.page(page: nextPage))
  }

  public func pullToRefresh() {
    load(.pullToRefresh)
  }

  open func appear() {
    switch state {
    case .notInitiated:
      state = .initiated
      load(.initial)
    default:
      if loadingBehavior.contains(.appearance) {
        load(.appearance)
      }
    }

    if loadingBehavior.contains(.autoupdate) {
      startAutoupdateIfNeeded()
    }
  }

  open func disappear() {
    if !loadingBehavior.contains(.autoupdateBackground) {
      timerDisposeBag = nil
    }
  }

  open func cancelLoading() {
    loaderDisposeBag = nil
    state = .initiated
  }
  
  public func reloadDataWithEmptyDataSet() {
    containerView?.reloadData()
    setupNoData(noDataState?(state))
    updateEmptyView?(state)
  }

  private func setupNoData(_ noDataSections: [Sectionable]?) {
    guard let stateSections = noDataSections else { return }
    sections = stateSections
    containerView?.reloadData()
  }

  fileprivate func handleLastCellDisplayed() {
    if !loadingBehavior.contains(.paging) {
      return
    }

    switch state {
    case .hasData:
      load(.page(page: nextPage))
    default:
      dump(state)
      print("Not ready for paging")
    }
  }

    fileprivate func startAutoupdateIfNeeded() {
        guard timerDisposeBag == nil else { return }
        let disposeBag = DisposeBag()
        Observable<Int>.timer(.seconds(Int(autoupdatePeriod)), period: .seconds(Int(autoupdatePeriod)), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.load(.autoupdate)
        }).disposed(by: disposeBag)
        timerDisposeBag = disposeBag
    }

    fileprivate func needToHandleIntent(intent: LoaderIntent) -> Bool {
    switch state {
    case .loading(let currentIntent):
      if intent == .force(keepData: false) || intent == .pullToRefresh {
        cancelLoading()
        return true
      } else if currentIntent == intent {
        return false
      } else {
        switch (intent, currentIntent) {
        case (.page, .page): return false
        default: return true
        }
      }
    default:
      return true
    }
  }

  // swiftlint:disable function_body_length
  // swiftlint:disable:next cyclomatic_complexity
  fileprivate func load(_ intent: LoaderIntent) {
    guard DispatchQueue.isMain else {
      return DispatchQueue.main.async {
        self.load(intent)
      }
    }

    guard needToHandleIntent(intent: intent) else { return }

    if intent == .force(keepData: false) {
      sections = []
      reloadDataWithEmptyDataSet()
    }
    guard let observable = loader?.load(into: self, for: intent) else { return }
    let cellsCountBeforeLoad = cellsCount
    state = .loading(intent: intent)
    let loaderDisposeBag = DisposeBag()
    self.loaderDisposeBag = loaderDisposeBag
    startProgress?(intent)
    observable
      .observeOn(MainScheduler.instance)
      .subscribe(onError: { [weak self] error in
        guard let `self` = self else { return }
        if self.cellsCount > 0 {
          self.state = .hasData
          self.updateEmptyView?(self.state)
          self.setupNoData(self.noDataState?(self.state))
        } else {
          self.state = .error(error)
          self.updateEmptyView?(self.state)
          self.setupNoData(self.noDataState?(self.state))
        }
      }, onCompleted: { [weak self] in
        guard let `self` = self else { return }
        let cellsCountAfterLoad = self.cellsCount

        switch intent {
        case .page:
          if cellsCountAfterLoad == cellsCountBeforeLoad {
            self.state = .hasData
            return
          }
        default: break
        }
        guard let containerView = self.containerView else { return }
        if cellsCountAfterLoad == 0 {
          self.state = .empty
          self.reloadDataWithEmptyDataSet()
        } else {
          self.state = .hasData
          guard let lastSection = self.sections.last else { return }
          guard let visibleItems = containerView.visibleItems else { return }
          let sectionsLastIndex = self.sections.count - 1
          let itemsLastIndex = lastSection.cells.count - 1

          if visibleItems.contains(where: { $0.section == sectionsLastIndex && $0.item == itemsLastIndex }) {
            self.handleLastCellDisplayed()
          }
        }
      }, onDisposed: { [weak self] in
        self?.stopProgress?(intent)
      }).disposed(by: loaderDisposeBag)
    updateEmptyView?(state)
  }

  fileprivate var nextPage: Int {
    let maxPage = sections.map({ $0.page }).max()
    return (maxPage ?? 0) + 1
  }
}
