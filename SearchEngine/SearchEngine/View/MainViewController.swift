import UIKit
import WebKit
import SnapKit

class MainViewController: UIViewController, WKScriptMessageHandler, WKUIDelegate  {
    
    lazy var progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?
    let searchBar = UISearchBar()
    var savedBookmarks: [String] = []
    
//    func addBookmarks() {
//        print("bookmarked")
//    }
    
    override func loadView() {
        super.loadView()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBookmarks()
        configureView()
        modelsToModifyView()
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
        self.activityIndicator.stopAnimating()
    }
    
    lazy var image: UIImageView = {
        var image = UIImageView()
        image.image = UIImage(named: "pip.fill")
        return image
    }()
    
    func createToolBarItems() {
        
        let bookMarkButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(bookMarkButtonCliked))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: webKitView, action: #selector(userContentController(_:didReceive:)))
        let spacerButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(clickedToRefresh))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancleButtonTapped))
        
        toolbarItems = [bookMarkButton, spacerButton, shareButton, spacerButton, refreshButton, spacerButton, cancelButton]
        navigationController?.isToolbarHidden = false
    }
    
    @objc func cancleButtonTapped() {
       navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func bookMarkButtonCliked() {
        if let text = searchBar.searchTextField.text {
            if !savedBookmarks.contains(text) && text.count > 0{
                savedBookmarks.append(text)
            }
            
        }
        UserDefaults.standard.set(savedBookmarks, forKey: "bookmark")

        let bookmark = BookMarkViewController()
        let navigationController = UINavigationController(rootViewController: bookmark)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func loadBookmarks() {
        if let bookmarks = UserDefaults.standard.object(forKey: "bookmark") as? [String] {
            savedBookmarks = bookmarks
        }
    }
    
    @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let dict = message.body as! [String:AnyObject]
        let username = dict["username"] as! String
        let secretToken = dict["secretToken"] as! String
        
        let av = UIActivityViewController(activityItems: [username, secretToken], applicationActivities: nil)
        self.present(av, animated: true, completion: nil)
    }
    
    private func setupProgressView() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        progressView.isHidden = true
        
        navigationBar.addSubview(progressView)
        progressView.snp.makeConstraints{ make in
            make.bottom.left.right.equalTo(navigationBar)
            make.height.equalTo(2.0)
        }
    }
    
    func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webKitView.observe(\.estimatedProgress, options: [.new]) { [weak self] webKitView, _ in
            self?.progressView.progress = Float(webKitView.estimatedProgress)
        }
    }
    
    lazy var stackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.clipsToBounds = true
        return stackView
    }()
    
    lazy var backButton: UIButton = {
        var backButton = UIButton()
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.isEnabled = false
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        return backButton
    }()
    
    lazy var containerView: UIView = {
        var containerView = UIView()
       return containerView
    }()
    
    lazy var bookMark: UIButton = {
        var bookMark = UIButton()
        bookMark.setImage(UIImage(systemName: "book"), for: .normal)
        bookMark.addTarget(self, action: #selector(clickToAddToBookmark), for: .touchUpInside)
        return bookMark
    }()
    
    lazy var nextButton: UIButton = {
        var nextButton = UIButton()
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.systemBlue, for: .normal)
        nextButton.isEnabled = false
        nextButton.addTarget(self, action: #selector(nextButtonCliked), for: .touchUpInside)
        return nextButton
    }()
    
    @objc func clickToAddToBookmark() {
        print("added to bookmark")
    }
    
    func configureSearchbarController() {
        searchBar.sizeToFit()
        searchBar.clipsToBounds = true
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.placeholder = Constants.MainViewStrings.searchBarplaceholder
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
//        searchBar.showsBookmarkButton = true
//        searchBar.searchTextField.clearButtonMode = .never
        searchBar.isTranslucent = true
        
    }
    
    lazy var imageStackView: UIStackView = {
        var imageStackView = UIStackView()
        return imageStackView
    }()
    lazy var scrollView: UIScrollView = {
        var scrollView = UIScrollView()
        scrollView.autoresizingMask = .flexibleHeight
        scrollView.bounces = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        var activityIndicator = UIActivityIndicatorView()
        activityIndicator.stopAnimating()
        return activityIndicator
    }()
    
    lazy var contentView: UIView = {
        var contentView = UIView()
        return contentView
    }()
    
    lazy var webKitView: WKWebView = {
        var webKitView = WKWebView()
        let prefrence = WKWebpagePreferences()
        let userContentController = WKUserContentController()
        prefrence.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.defaultWebpagePreferences = prefrence
        userContentController.add(self, name: "userLogin")
        webKitView.uiDelegate = self
        
        webKitView.addSubview(activityIndicator)
        webKitView.allowsBackForwardNavigationGestures = true
        webKitView.allowsLinkPreview = true
        webKitView.navigationDelegate = self
        self.activityIndicator.startAnimating()
        self.activityIndicator.hidesWhenStopped = true
        return webKitView
    }()
    
    @objc func backButtonClicked() {
        if webKitView.canGoBack {
            webKitView.goBack()
        }
    }
    
    @objc func nextButtonCliked() {
        if webKitView.canGoForward {
            webKitView.goForward()
        }
    }
    
    func didPullToRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webKitView.scrollView.addSubview(refreshControl)
    }
    
    @objc func clickedToRefresh() {
        webKitView.reload()
    }
    
    @objc func reloadWebView(_ sender: UIRefreshControl) {
        sender.beginRefreshing()
        self.webKitView.reload()
        self.refreshDidStop(sender)
    }
    
    func refreshDidStop(_ sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            sender.endRefreshing()
        })
    }
    
    func fetchDataFromWebkit(urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        webKitView.load(URLRequest(url: url))
    }
    
        
    }
    

