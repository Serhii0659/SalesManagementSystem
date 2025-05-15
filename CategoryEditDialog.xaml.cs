using System.Windows;

namespace SalesManagementSystem
{
    public partial class CategoryEditDialog : Window
    {
        public string CategoryName => NameBox.Text.Trim();

        public CategoryEditDialog(string name)
        {
            InitializeComponent();
            NameBox.Text = name;
            NameBox.Focus();
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(NameBox.Text))
            {
                MessageBox.Show("Назва категорії не може бути порожньою.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            DialogResult = true;
        }
    }
}