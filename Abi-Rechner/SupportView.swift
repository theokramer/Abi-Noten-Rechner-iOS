import SwiftUI
import UIKit
import MessageUI

struct SupportView: View {
    @EnvironmentObject var user: UserStore
    @State var result: Result<MFMailComposeResult, Error>?
      @State var isShowingMailView = false
    var body: some View {
        ZStack {
            Color.modeColor
            VStack {
                if tablet {
                    ZStack {
                        Color.modeColor
                        HStack {
                            
                            Image(systemName: "xmark").resizable().aspectRatio(contentMode: .fit).frame(width: 30).padding()
                            Spacer()
                            Image(systemName: "")
                        }
                    }.frame(width: screen.width, height: 50).onTapGesture {
                        print("hi")
                        user.supportClicked = false
                        user.siteOpened = 0
                        print(user.siteOpened)
                        
                    }
                }
                Text("Support").font(.title)
                // swiftlint:disable:next line_length
                Text("Hast du einen Fehler in der App gefunden, oder wünschst du dir ein neues Feature? Lass es mich wissen und schreibe mir eine Mail mit deinen Verbesserungsvorschlägen.").multilineTextAlignment(.center).padding(.top, 10)
                ZStack {
                    RoundedRectangle(cornerRadius: 10).foregroundColor(Color("Orange"))
                    HStack {
                        Text("Mail schreiben").foregroundColor(.modeColor)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.modeColor)
                    }.padding(.horizontal, 15)
                }.frame(width: tablet ? 300 : screen.width * 0.85, height: 55).padding(.horizontal).padding(.top, 12).onTapGesture {
                    user.supportClicked = false
                    user.sendEmail = true
                    user.siteOpened = 0
                }
                Spacer()
            }.padding(20)
        }
    }
}

class EmailService: NSObject, MFMailComposeViewControllerDelegate {
public static let shared = EmailService()

func sendEmail(subject: String, body: String, to: String, completion: @escaping (Bool) -> Void) {
 if MFMailComposeViewController.canSendMail() {
    let picker = MFMailComposeViewController()
    picker.setSubject(subject)
    picker.setMessageBody(body, isHTML: true)
    picker.setToRecipients([to])
    picker.mailComposeDelegate = self
    
   UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true, completion: nil)
}
  completion(MFMailComposeViewController.canSendMail())
}

func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
     }
}
