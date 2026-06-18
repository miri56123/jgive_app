puts "Seeding campaigns..."

campaign1 = Campaign.find_or_create_by!(title: "הגן הכתום") do |c|
  c.subtitle = "לזכר בני משפחת ביבס וילדי ה-7 באוקטובר"
  c.organization_name = "עמותת וְנָטַעְתָּ"
  c.goal_amount = 2_000_000
  c.bonus_goal_amount = 5_000_000
  c.status = :active
  c.cover_image_url = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&auto=format&fit=crop"
  c.description = <<~HTML
    <h2>הצטרפו עכשיו והיו ממקימי הגן הכתום</h2>
    <h3>לזכר שירי, אריאל וכפיר ביבס, ולזכר כל ילדי ה-7 באוקטובר.</h3>
    <p>אחרי שנתיים וחצי של כאב, טלטלה והתמודדות, מגיע מיזם שמביא בשורה חדשה לישראל — <strong>מקום של חיים, ריפוי ותקווה.</strong></p>
    <p>אנחנו יוצאים לדרך עם הקמת <strong>הגן הכתום</strong> — מרחב ראשון מסוגו בישראל שמחבר זיכרון, טבע, ילדים וריפוי.</p>
    <p>על פני <strong>20 דונם</strong> יוקם מרחב חי של טבע, מים, משחק, משפחה וריפוי — פתוח לכולם.</p>
    <h3>מה יחכה לנו בגן הכתום?</h3>
    <ul>
      <li><strong>מתחם גינון טיפולי-קהילתי</strong> — מרחב ריפוי דרך הטבע עבור הלומי קרב, בני הגיל השלישי ונוער בסיכון</li>
      <li><strong>בוסתני פרי ומטעים</strong> — הליכה בין עצי פרי, בהשראת הפירות ששירי ואריאל אהבו</li>
      <li><strong>הנחל האקולוגי</strong> — נחל זורם עם גשרי עץ קטנים ומים חיים</li>
      <li><strong>מרחב זיכרון</strong> — פינה מכבדת לזכר ילדי השבעה באוקטובר</li>
      <li><strong>האומגה הכתומה ומתקני משחק</strong> — כי צחוק של ילדים הוא התשובה הכי חזקה לכאב</li>
      <li><strong>קיר המשאלות</strong> — מקום שבו כל ילד וילדה יוכלו להשאיר משאלה, תפילה, תקווה או חלום</li>
      <li><strong>אמפיתיאטרון וכיתות חוץ</strong> — מקום להופעות, פעילות חינוכית וקהילתית</li>
    </ul>
    <p>הפרויקט הוא יוזמה של עמותת ונטעת, בשיתוף משפחת ביבס ועיריית מגדל העמק.</p>
  HTML
end

campaign2 = Campaign.find_or_create_by!(title: "מזון לכל") do |c|
  c.subtitle = "מאבק ברעב ובעוני בישראל"
  c.organization_name = "עמותת לחם לכל"
  c.goal_amount = 500_000
  c.status = :active
  c.cover_image_url = "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=1200&auto=format&fit=crop"
  c.description = <<~HTML
    <h2>מזון לכל — לא עוד ילד ישן רעב</h2>
    <p>כ-400,000 ילדים בישראל חיים בעוני ומחוסרי מזון. עמותת לחם לכל פועלת כבר 15 שנה לחלוקת סלי מזון, ארוחות חמות ותמיכה לאלפי משפחות מדי שבוע.</p>
    <p><strong>התרומה שלכם תעזור לממן:</strong></p>
    <ul>
      <li>סלי מזון שבועיים ל-500 משפחות</li>
      <li>ארוחות חמות יומיות ל-200 ילדים</li>
      <li>מלגות לרכישת ציוד לבית הספר</li>
    </ul>
    <p>כל שקל חשוב. כל תרומה מצילה.</p>
  HTML
end

puts "Seeded #{Campaign.count} campaigns"

puts "Seeding donations..."

donors = [
  { name: "ישראל כהן",      dedication: "לזכר שירי ז\"ל" },
  { name: "מיכל לוי",       dedication: nil },
  { name: "דוד ברגר",       dedication: "לרפואת כל פצועי ישראל" },
  { name: "רחל גולדמן",     dedication: nil },
  { name: "עמי שפירא",      dedication: "לזכר כל ילדי ה-7 באוקטובר" },
  { name: "נועה רוזנברג",   dedication: nil },
  { name: "ארי פינקל",      dedication: "לזכר אריאל וכפיר ז\"ל" },
  { name: "שרה אברמוביץ",   dedication: nil },
  { name: "יוסי מזרחי",     dedication: "בשם משפחת מזרחי" },
  { name: "לילך בן-דוד",    dedication: nil }
]

amounts = [ 180, 260, 360, 500, 1_000, 1_800, 90, 120, 300 ]
display_prefs = %i[full_name first_name_only anonymous]

Donation.delete_all

10.times do |i|
  donor = donors[i]
  recurring = i.odd?
  Donation.create!(
    campaign: campaign1,
    donor_name: donor[:name],
    amount: amounts[i % amounts.length],
    status: i < 8 ? :paid : :pending,
    frequency: recurring ? :recurring : :one_time,
    months: recurring ? [ 6, 12, 24, 36 ][i / 2 % 4] : nil,
    display_preference: display_prefs[i % 3],
    dedication_message: donor[:dedication]
  )
end

6.times do |i|
  donor = donors[(i + 3) % donors.length]
  Donation.create!(
    campaign: campaign2,
    donor_name: donor[:name],
    amount: amounts[(i + 2) % amounts.length],
    status: i < 4 ? :paid : :pending,
    frequency: :one_time,
    display_preference: i.even? ? :full_name : :first_name_only,
    dedication_message: donor[:dedication]
  )
end

Donation.create!(
  campaign: campaign1,
  donor_name: "קרן משפחת לוינשטיין",
  amount: 800_000,
  status: :paid,
  frequency: :one_time,
  display_preference: :full_name,
  dedication_message: "לזכר ילדי ה-7 באוקטובר"
)

puts "Seeded #{Donation.count} donations"
puts "Done!"
