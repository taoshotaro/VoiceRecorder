import Reusable
import UIKit

protocol WaveViewDelegate {
//    func timeChanged(time: CGFloat)
    func timeChangeBegin()
    func timeChnageEnd()
}

final class WaveView: UIView, NibOwnerLoadable {
    var lineWidth: CGFloat = 4 // moto 2
    var linePadding: CGFloat = 3 // moto 1
    private var playTimer: Timer?
    var delegate: WaveViewDelegate?
    var now: CGFloat = 0

    @IBOutlet var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(cellType: WaveCollectionViewCell.self)
            collectionView.backgroundColor = .clear
            collectionView.alwaysBounceVertical = false
            collectionView.alwaysBounceHorizontal = false
            collectionView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        }
    }
    
    private var isScrollManually = true
    var animator: UIViewPropertyAnimator?

    private var waves: [CGFloat] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        backgroundColor = .clear
    }

    func addWave(wave: CGFloat) {
        let newIndexPath = IndexPath(item: 0, section: 0)
        waves.insert(wave, at: 0)
        collectionView.insertItems(at: [newIndexPath])
        setNow()
    }

    func reset() {
        waves.removeAll()
        collectionView.reloadData()
    }
    
    func remove(from: Int, complet: (() -> Void)? = nil) {
        if !waves.isEmpty && from != (waves.count - 1) {
            waves = Array(waves[(waves.count - from)..<waves.count])
            collectionView.reloadData()
            collectionView.contentOffset = CGPoint(x: 0, y: CGFloat(waves.count) * lineWidth + CGFloat(waves.count) * linePadding - linePadding)
            self.layoutIfNeeded()
            setNow()
            complet?()s
        }
    }
    
    func play() {
        isScrollManually = false
        
        if collectionView.contentOffset.x <= 0 || collectionView.contentOffset.x > lineWidth * CGFloat(waves.count) + CGFloat(waves.count) * linePadding - linePadding {
            
            collectionView.contentOffset = CGPoint(x: (lineWidth * CGFloat(waves.count) + CGFloat(waves.count) * linePadding - linePadding), y: 0)
        }
        
        playTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(animateCell), userInfo: nil, repeats: true)
        
        isScrollManually = true
    }
    
    @objc func animateCell() {
        isScrollManually = false
        var offsetX = self.collectionView.contentOffset.x - (lineWidth + linePadding)
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
            if offsetX < 0 {
                offsetX = 0
            }
            self.collectionView.contentOffset = CGPoint(x: offsetX, y: 0)
        }) { _ in
            self.isScrollManually = true
        }
        if offsetX == 0 {
            playTimer?.invalidate()
        }
    }
    
    private func setNow() {
        var time = (collectionView.contentSize.width - collectionView.frame.width - collectionView.contentOffset.x)
        time = time.isNaN ? 0 : time
        let insideAll = (collectionView.contentSize.width - collectionView.frame.width)
        var realTime = floor(time * CGFloat(waves.count) / insideAll) * 0.1
        realTime = realTime.isNaN ? 0 : realTime
        now = realTime
        print(now)
    }
}

extension WaveView: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return waves.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as WaveCollectionViewCell
        cell.value = waves[indexPath.row]
        cell.waveState = .Recording
        cell.line.layer.cornerRadius = 1
        cell.line.clipsToBounds = true
        return cell
    }
}

extension WaveView: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrollManually {
            playTimer?.invalidate()
            
            setNow()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.timeChangeBegin()
        print("scrollViewWillBeginDragging")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !(collectionView.contentOffset.x <= 0 || collectionView.contentOffset.x > CGFloat(2 * waves.count + waves.count - 1)) {
            delegate?.timeChnageEnd()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.timeChnageEnd()
    }
}

extension WaveView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: lineWidth, height: collectionView.frame.height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return linePadding
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: collectionView.frame.width / 2, bottom: 0, right: collectionView.frame.width / 2)
    }
}
