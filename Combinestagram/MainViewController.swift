/*
 * Copyright (c) 2016-present Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

    let bag = DisposeBag()
    let images = Variable<[UIImage]>([])
    var imageCache = [Int]()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    images.asObservable().subscribe(onNext: { photos in
        guard let preview = self.imagePreview else { return }
        preview.image = UIImage.collage(images: photos, size: preview.frame.size)
        self.updateUI(photos: photos)
    }).disposed(by: bag)
  }
  
  @IBAction func actionClear() {
    images.value = []
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image).asSingle().subscribe(onSuccess: { id in
        self.showMessage("Saved with id: \(id)")
        self.actionClear()
    }, onError: { error in
        self.showMessage("Error:", description: error.localizedDescription)
    }).disposed(by: bag)
  }

  @IBAction func actionAdd() {
    let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
    let newPhotos = photosViewController.selectedPhotos.share()
    
    newPhotos.takeWhile({ (image) -> Bool in
        return (self.images.value.count) < 6
    }).filter { (image) -> Bool in
        return image.size.width > image.size.height
        }.filter { (image) -> Bool in
            let length = UIImagePNGRepresentation(image)?.count ?? 0
            guard self.imageCache.contains(length) == false else { return false }
            self.imageCache.append(length)
            return true
        }.subscribe(onNext: { newImage in
            self.images.value.append(newImage)
        }, onDisposed: {
            print("Completed photo selection")
        }).disposed(by: bag)
    
    newPhotos.ignoreElements().subscribe(onCompleted: {
        self.updateNavigationIcon()
    }).disposed(by: bag)
    
    navigationController?.pushViewController(photosViewController, animated: true)
  }

  func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
    present(alert, animated: true, completion: nil)
  }
    
    func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
    
    func updateNavigationIcon() {
        let icon = imagePreview.image?.scaled(CGSize(width: 22, height: 22)).withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
}
