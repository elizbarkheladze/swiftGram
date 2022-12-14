//
//  MainFeedController.swift
//  SwiftaGram
//
//  Created by alta on 9/5/22.
//

import UIKit
import Firebase

private let reuseIdentifier = "Cell"

class MainFeedController: UICollectionViewController {
    
    private var  usersPosts = [UserPost]()
     var userPost: UserPost?
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchPosts()
        
        
    }
    //MARK: - API
    
    func fetchPosts(){
        guard  userPost == nil else  { return }
        UserPostService.fetchPosts { posts in
            self.usersPosts = posts
            self.collectionView.refreshControl?.endRefreshing()
            self.isPostLiked()
            self.collectionView.reloadData()
        }
    }
    
    func isPostLiked() {
        self.usersPosts.forEach{ userPost in
            UserPostService.hasUserLikedPost(userPost: userPost) { liked in
                if let index = self.usersPosts.firstIndex(where: {$0.postID  == userPost.postID}) {
                    self.usersPosts[index].didLike = liked
                    print("KAKA : \(liked)")
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    //MARK: - Actions
    @objc func logOutUser(){
        do {
            try Auth.auth().signOut()
            let vc = LoginController()
            vc.delegate = self.tabBarController as? TabBarController
            let navigation = UINavigationController(rootViewController: vc)
            navigation.modalPresentationStyle = .fullScreen
            self.present(navigation, animated: true,completion: nil)
        }catch{
            print("Failed to Sign out")
        }
    }
    @objc func refresh(){
        usersPosts.removeAll()
        fetchPosts()
    }
    
    // MARK: - Helpers
    func configureUI() {
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.backgroundColor = .white
        collectionView.register(MainFeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.refreshControl = refresher
        if userPost == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "LOg Out", style: .plain,
                                                                target: self, action: #selector(logOutUser))
        }
        
        navigationItem.title = "Feed"
    }
}

// MARK: - UIcollectionViewDataSource

extension MainFeedController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPost == nil ? usersPosts.count : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainFeedCell
        cell.delegate = self
        if let userPost = userPost {
            cell.viewModel = UersPostViewModel(userpost: userPost)
        }else {
            cell.viewModel = UersPostViewModel(userpost: usersPosts[indexPath.row])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainFeedController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = view.frame.width
        var height = width + 8 + 40 + 8
        height += 110
        return CGSize(width:width,height:height)
    }
}

extension MainFeedController : MainFeedCellDelegate {
    func profileTapped(_ cell: MainFeedCell, uid: String) {
        UserService.fetchUser(uid: uid) { user in
            let vc = UserProfileController(user: user)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func postLikeTapped(_ cell: MainFeedCell, userPost: UserPost) {
        guard let tabBarCont = self.tabBarController as? TabBarController else {return}
        guard let user = tabBarCont.user else {return}
        
        cell.viewModel?.userpost.didLike.toggle()
        if userPost.didLike {
            UserPostService.postUnliked(userPost: userPost) { error in
                cell.likeBtn.setImage(UIImage(imageLiteralResourceName: "like_unselected"), for: .normal)
                cell.likeBtn.tintColor = .black
                cell.viewModel?.userpost.like = userPost.like - 1
            }
            
        }else {
            UserPostService.postLiked(userPost: userPost) { error in
                cell.likeBtn.setImage(UIImage(imageLiteralResourceName: "like_selected"), for: .normal)
                cell.likeBtn.tintColor = .red
                cell.viewModel?.userpost.like = userPost.like + 1
                
                UserNotificationsService.sendUserNotification(uid: userPost.publisherID,user: user, type: .liked, userPost: userPost)
            }
        }
    }
    
    func tappedCommentsOnCell(_ cell: MainFeedCell, userPost: UserPost) {
        let vc = CommentsController(userPost: userPost)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
