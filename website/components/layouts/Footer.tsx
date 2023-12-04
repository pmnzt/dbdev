import Link from 'next/link'

export const links = [
  { title: ` © Supabase`, url: 'https://supabase.com/' },
  { title: 'FAQs', url: '/faq' },
  { title: 'Open Source', url: 'https://supabase.com/open-source' },
  { title: 'Privacy Settings', url: 'https://supabase.com/privacy' },
]

const Footer = () => (
  <footer
    role="menu"
    className="container border-t py-4 w-full px-4 flex justify-between"
  >
    <ul className="flex items-center gap-4 text-xs md:text-sm">
      {links.map((link, index) => (
        <li key={index}>
          <Link href={link.url}>{link.title}</Link>
        </li>
      ))}
    </ul>
  </footer>
)

export default Footer
